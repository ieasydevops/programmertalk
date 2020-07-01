---
title: WAL
linktitle: WAL
toc: true
type: docs
date: "2019-05-05T00:00:00+01:00"
draft: false
menu:
  tsdb:
    parent: TSDB
    weight: 10

# Prev/next pager order (if `docs_section_pager` enabled in `params.toml`)
weight: 10
---

## 目录

- 概览
- WAL管理
- WAL Read/Writer
- Log file 格式
- Record 文件格式
- 格式的优缺点
- WAL的实现

## 概览

Write ahead log (WAL) 以日志文件的形式将内存表的操作顺序的持久化到存储介质上。在失败的时候，WAL文件 通过利用这些日志文件重建内存表，来恢复数据库到之前一致的状态。当一个内存表被安全的刷写到持久化介质后，对应的WLA日志会逐步的归档和淘汰，最终
归档的日志经过一个时间后会从磁盘清理掉。

## WAL管理

WAL文件是有在WAL目录下递增的序列号生成，为了能恢复到database的状态，这些文件需要按照序列号来读。WAL管理器，
提供了将WAL文件作为单个单元读取的抽象。在内部，它使用Reader或Writer抽象来打开和读取文件。


## WAL Reader/Writer

Writer 为向日志记录提供了一个抽象。存储媒介特定的内部细节，通过WriteableFile 接口屏蔽掉。
类似地，Reader提供了 从特定日志文件中顺序读取日志记录的抽象。内部存储媒介的详细信息有 SequentailFile 接口处理。


## Log File 格式

日志文件有一系列可变长度的记录组成。记录按kBlockSize分组。如果某个记录无法放入剩余空间，则剩余空间将填充null数据。
Writer 以kBlockSize为单位进行读/写

```
       +-----+-------------+--+----+----------+------+-- ... ----+
 File  | r0  |        r1   |P | r2 |    r3    |  r4  |           |
       +-----+-------------+--+----+----------+------+-- ... ----+
       <--- kBlockSize ------>|<-- kBlockSize ------>|

  rn = variable size records
  P = Padding

```



## Record 文件格式

Record 的布局格式有两种： Legacy 和 Recyclable

### The Legacy Record Format


```
+---------+-----------+-----------+--- ... ---+
|CRC (4B) | Size (2B) | Type (1B) | Payload   |
+---------+-----------+-----------+--- ... ---+

CRC = 32bit hash computed over the payload using CRC
Size = Length of the payload data
Type = Type of record
       (kZeroType, kFullType, kFirstType, kLastType, kMiddleType )
       The type is used to group a bunch of records together to represent
       blocks that are larger than kBlockSize
Payload = Byte stream as long as specified by the payload size

```


 ### Recyclable Record Format


```
+---------+-----------+-----------+----------------+--- ... ---+
|CRC (4B) | Size (2B) | Type (1B) | Log number (4B)| Payload   |
+---------+-----------+-----------+----------------+--- ... ---+
Same as above, with the addition of
Log number = 32bit log file number, so that we can distinguish between
records written by the most recent log writer vs a previous one.

```



## Record Format Details For Legacy Format

日志文件内容是一个32KB块的序列。唯一的例外是文件的尾部可能包含部分块。

每一个block 包含一系列记录组成:

```

block := record* trailer?
record :=
  checksum: uint32	// crc32c of type and data[]
  length: uint16
  type: uint8		// One of FULL, FIRST, MIDDLE, LAST 
  data: uint8[length]

```

记录永远不会在块的最后6个字节内开始（因为它不适合）。这里的任何剩余字节都构成了尾部，它必须完全由零字节组成，并且必须被读者跳过。

> 如果当前的block 还剩下 7 个 bytes, 当新增一个非零长度的record时，写入的 writer 必须先发出一个记录(其中包含零字节
的用户数据)以填充block 尾部的 7 个 bytes ,然后在后续的block 中，发出用户的所有数据

用户的记录的数据类型如下：

```
FULL == 1
FIRST == 2
MIDDLE == 3
LAST == 4

```
以后可以有更多的数据类型，一些 Readers 可能会跳过他们不理解的recored, 也有一些Readers 或报告 这些数据被忽略。

Full record 或包含整个用户记录。

FIRST, MIDDLE, LAST, 是用于用户记录的类型，这些类型被分割为多个片段（通常是因为block 的边界）。
FIRST: user record 的第一个片段的类型
LAST:  user record 的最后一个片段的类型
MID: 是用户记录的所有内部片段的类型。


举例:

一序列用户的 records 

A: length 1000

B: length  97270

C: length 8000

A 会作为完整记录存储在第一个block中
B 会拆分成三个block. 第一个fragment 占据第一个block 剩余的部分
第二个 fragment 会占据第二个block 的所有
第三个 fragment 会占据第三个block 的前半部分，这将在第三个block中留下6个bytes  的空闲空间，该block 作为
尾部留空
C 作为完整的记录存在第四个block 中


## 优势

1. 不需要任何启发式 resyncing  ， 只需要转到下一个block 边界 ，扫描。如果又损坏，请跳到
下一个block。作为一个附带的好处，当一个日志文件的部分内容作为recode 潜入到另一个日志文件中时，我们
不会感到困惑。

2. Splitting at approximate boundaries (e.g., for mapreduce) is simple: 

找到下一个block 并跳过记录，直到找到完整的或第一个记录为止。

3. 对于大的记录，我们不需要额外的缓冲。

缺点:

1. 不能打包小的 records. 这个可以通过添加新的类型来解决，这是当前实现的一个缺点
2. 不能压缩。同样，这个可以通过增加记录的类型来解决这个问题


##  WAL的实现

### WLA 文件格式

WAL  按编号和顺序的段操作

·000000·
·000001·
·000002·
·000003·

默认最大128M，

以32KB的页数写入一个段。只有最近一段的最后一页可能是不完整的。WAL记录是一个不透明的字节片，如果超过当前页面的剩余空间，
,它被拆分成子记录。在 segment 边界，记录永远不会分开，如果单个记录超过默认段大小，则将创建更大尺寸的segment.

Prometheus tsdb 的WAL格式如下：

```
┌───────────┬──────────┬────────────┬──────────────┐
│ type <1b> │ len <2b> │ CRC32 <4b> │ data <bytes> │
└───────────┴──────────┴────────────┴──────────────┘



```

类型标签又如下几种状态：

* `0`: rest of page will be empty
* `1`: a full record encoded in a single fragment
* `2`: first fragment of a record
* `3`: middle fragment of a record
* `4`: final fragment of a record


###  记录的编码格式

分三种类型

* 序列记录
* 样本记录
* Tombstone 类型

Series records encode the labels that identifies a series and its unique ID.

#### 序列记录

一个序列记录，会包含该序列的标签和唯一ID

```
┌────────────────────────────────────────────┐
│ type = 1 <1b>                              │
├────────────────────────────────────────────┤
│ ┌─────────┬──────────────────────────────┐ │
│ │ id <8b> │ n = len(labels) <uvarint>    │ │
│ ├─────────┴────────────┬─────────────────┤ │
│ │ len(str_1) <uvarint> │ str_1 <bytes>   │ │
│ ├──────────────────────┴─────────────────┤ │
│ │  ...                                   │ │
│ ├───────────────────────┬────────────────┤ │
│ │ len(str_2n) <uvarint> │ str_2n <bytes> │ │
│ └───────────────────────┴────────────────┘ │
│                  . . .                     │
└────────────────────────────────────────────┘
```


#### 采集样本记录

采样数据样本记录 主要包含了 三元组 `（序列ID，时间戳，序列值Value）`
序列的索引ID和时间戳  被编码为 w.r.t 
第一个行存储了启始的ID 和启始的时间戳。

```
┌──────────────────────────────────────────────────────────────────┐
│ type = 2 <1b>                                                    │
├──────────────────────────────────────────────────────────────────┤
│ ┌────────────────────┬───────────────────────────┐               │
│ │ id <8b>            │ timestamp <8b>            │               │
│ └────────────────────┴───────────────────────────┘               │
│ ┌────────────────────┬───────────────────────────┬─────────────┐ │
│ │ id_delta <uvarint> │ timestamp_delta <uvarint> │ value <8b>  │ │
│ └────────────────────┴───────────────────────────┴─────────────┘ │
│                              . . .                               │
└──────────────────────────────────────────────────────────────────┘
```


#### Tombstone记录
 
Tombstone records encode tombstones as a list of triples `(series_id, min_time, max_time)`
and specify an interval for which samples of a series got deleted.


```
┌─────────────────────────────────────────────────────┐
│ type = 3 <1b>                                       │
├─────────────────────────────────────────────────────┤
│ ┌─────────┬───────────────────┬───────────────────┐ │
│ │ id <8b> │ min_time <varint> │ max_time <varint> │ │
│ └─────────┴───────────────────┴───────────────────┘ │
│                        . . .                        │
└─────────────────────────────────────────────────────┘
```


### WLA 顶层接口设计


数据结构设计

```

// WAL is a write ahead log that stores records in segment files.
// It must be read from start to end once before logging new data.
// If an error occurs during read, the repair procedure must be called
// before it's safe to do further writes.
//
// Segments are written to in pages of 32KB, with records possibly split
// across page boundaries.
// Records are never split across segments to allow full segments to be
// safely truncated. It also ensures that torn writes never corrupt records
// beyond the most recent segment.
type WAL struct {
	dir         string
	logger      log.Logger
	segmentSize int
	mtx         sync.RWMutex
	segment     *Segment // Active segment.
	donePages   int      // Pages written to the segment.
	page        *page    // Active page.
	stopc       chan chan struct{}
	actorc      chan func()
	closed      bool // To allow calling Close() more than once without blocking.
	compress    bool
	snappyBuf   []byte

	metrics *walMetrics
}

```

### 段 Segment 

默认128M，


### 页 Page

页是内存的buffer , 用来向磁盘批量刷数据。 
如果 Records 比一个页大，此记录会被分割，并单独的刷写到磁盘。

磁盘的刷写动作在如下情况被触发：
1. 当一个记录不适合当前的page 大小
2. 或剩下的空间放不下下一个记录

```

// page is an in memory buffer used to batch disk writes.
// Records bigger than the page size are split and flushed separately.
// A flush is triggered when a single records doesn't fit the page size or
// when the next record can't fit in the remaining free page space.
type page struct {
	alloc   int
	flushed int
	buf     [pageSize]byte
}

```

### WAL 初始化

1. 根据目录，获取segment列表
2. 创建最后一个segment

// New returns a new WAL over the given directory.
func New(logger log.Logger, reg prometheus.Registerer, dir string, compress bool) (*WAL, error) {
	return NewSize(logger, reg, dir, DefaultSegmentSize, compress)
}