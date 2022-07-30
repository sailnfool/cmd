#!/bin/bash
verbosemode=0   #Paradoxically 0 means true and 1 means false in bash,
                #but would allow me to write:
if [[ “${verbosemode}” ]]
then
…
fi
