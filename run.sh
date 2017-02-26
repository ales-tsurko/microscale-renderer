#!/bin/bash
echo "includePaths:
    - app/SuperCollider.app/Contents/Resources/SCClassLibrary
excludePaths:
    - $HOME/Library/Application Support/SuperCollider/Extensions
    - /Library/Application Support/SuperCollider/Extensions
    - /Applications/SuperCollider.app/Contents/Resources/SCClassLibrary
postInlineWarnings: false" > langconf.yaml;
./app/SuperCollider.app/Contents/MacOS/sclang -a -l langconf.yaml main.scd
