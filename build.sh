#!/bin/sh
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

VERSION=10.1.0
PACKAGE="Octave-doc-$VERSION.tgz"
DOC_DIR=v$VERSION
DOC_HOST="docs.octave.org"
DOC_URL="https://$DOC_HOST/$DOC_DIR/"

if [ ! -f "$PACKAGE" ]; then
    printf "${GREEN}Starting to build octave.docset for version $VERSION${NC}\n"

    version=
    [ -f .version ] && version=$( cat .version )

    if [ ! .$VERSION = .$version ]; then
        # clean up previous remains, if any
        rm -rf Contents/Resources
        rm -rf Octave.docset

        # Prepare to grab the files
        mkdir -p Contents/Resources
        cd Contents/Resources

        # fetch the whole doc site
        printf "${GREEN}Starting to download Octave $VERSION documentation from $DOC_URL${NC}\n"
        wget --mirror --page-requisites --adjust-extension --convert-links --no-parent -e robots=off --show-progress --quiet "$DOC_URL"

        # change folder name to just Documents
        mv $DOC_HOST/$DOC_DIR ./Documents
        rm -rf $DOC_HOST

        if [ ! -f "Documents/Function-Index.html" ]; then
            printf "${RED}WARNING - wget failed at mirroring the site.${NC}\n"

            ldocdir=/usr/share/doc/octave/octave.html
            if [ -d "$ldocdir" ]; then
                printf "${GREEN}Using local octave html doc.${NC}\n"
                cp -a "$ldocdir" ./Documents
            else
                printf "${RED}ERROR - local Octave documents site not found.${NC}\n"
                exit 0
            fi
        fi
        cd ../../

        echo "$VERSION" > .version
    fi

    # bundle up!
    printf "${GREEN}Building the Octave.docset folder...${NC}\n"

    if [ ! -d Octave.docset ]; then
        mkdir Octave.docset
        cp -r Contents Octave.docset/
        cp assets/icon* Octave.docset/
    fi

    # create data file from base index page
    python3 octdoc2set.py

    if [ $? -eq 1 ]; then
        printf "${RED}Error: Could not build Docset${NC}\n"
        exit 1;
    fi

    # Create gzip bundle for Dash Contribution
    printf "${GREEN}Archiving to $PACKAGE ...${NC}\n"
    tar --remove-files --exclude='.DS_Store' -czf $PACKAGE Octave.docset
    printf "${GREEN}Finished!${NC}\n"
else
    printf "${GREEN}Archive: $PACKAGE alread exist.${NC}\n"
fi
