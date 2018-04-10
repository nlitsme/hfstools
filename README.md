hfstool
=======

Tools for reading Apple HFS+ filesystem images, written in perl.

Note: i wrote this about 16 years ago, in 2002, to help recovering data from a accidentally destroyed filesystem.

I do not intent to improve this project any further.


| file               | description
| ------------------ | -----------------------------------
| bm.pl              | binary operations on bitmap files
| diffls.pl          | compares ls -lR outputs
| dumpbtree.pl       | dumps btree from saved cat+attr+ext files
| findcat.pl         | find catalog on raw disk
| findextendrec.pl   | find extents on raw disk
| tsthfs.pl          | no program, just fns opening /dev/rdisk0s2
| dumpblock.pl       | dumps disk block from /dev/rdisk0s2
| dumphfs.pl         | dumps hfs bitmap summary from /dev/rdisk0s2
| dumphfstree.pl     | dumps hfs cnid tree from /dev/rdisk0s2,  optionally dump only one node
| searchhfs.pl       | reads /dev/rdisk0s2,   searches unalloced space for  pattern
| dmg2iso.pl         |
| makgimg.pl         | creates large empty file
| AttributeParser.pm | 
| Bitmap.pm          | 
| CatalogParser.pm   | 
| ExtentParser.pm    | 
| HFSBtree.pm        | 
| HFSFile.pm         | 
| HFSForkData.pm     | 
| HFSUtils.pm        | 
| HFSVolume.pm       | 
| Harddisk.pm        | 
| Hexdump.pm         | 


EXAMPLE
=======

    perl dumphfs.pl     --disk "/dev/rdisk2s2"

    perl dumphfstree.pl --disk "/dev/rdisk2s2" 4


AUTHOR
======

Willem Hengeveld <itsme@xs4all.nl>

