#!/bin/bash
hugo
git add .
git commit -m "update"
git push
git subtree push --prefix=public origin gh-pages
