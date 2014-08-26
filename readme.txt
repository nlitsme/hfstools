bm.pl              binary operations on bitmap files
diffls.pl          compares ls -lR outputs
dumpbtree.pl       dumps btree from saved cat+attr+ext files

findcat.pl         find catalog on raw disk
findextendrec.pl   find extents on raw disk
tsthfs.pl          no program, just fns opening /dev/rdisk0s2

dumpblock.pl       dumps disk block from /dev/rdisk0s2
dumphfs.pl         dumps hfs bitmap summary from /dev/rdisk0s2
dumphfstree.pl     dumps hfs cnid tree from /dev/rdisk0s2,  optionally dump only one node
searchhfs.pl       reads /dev/rdisk0s2,   searches unalloced space for  pattern

dmg2iso.pl
makgimg.pl         creates large empty file

AttributeParser.pm
Bitmap.pm
CatalogParser.pm
ExtentParser.pm
HFSBtree.pm
HFSFile.pm
HFSForkData.pm
HFSUtils.pm
HFSVolume.pm
Harddisk.pm
Hexdump.pm
