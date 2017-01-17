Choroid map processing
----------------------”

The user has to have writing rights on the directory holding the raw files.

To prepare choroid maps, call the following functions in serial order:

1 - convertSpectralis (batch)
2 - trimDetails (interactive)
3 - mapPseudoRegistration (batch)
4 - retinaLayersSegmentation (batch)
5 - choroidMap (batch)
6 - choroidMovie (batch)

each function takes as parameters a cell array of strings, each containing 
the path of one experiment data.


