package CatalogParser;
use strict;
use warnings;
use HFSUtils;
our %types=(
    1=> { name=>"folder"}, 
    2=> { name=>"file"}, 
    3=> { name=>"folder"}, 
    4=> { name=>"file"}, 
);
sub new { return bless { bitmap=>Bitmap->new(), quicklist=>$_[1] }, $_[0]; }

sub parse {
    my %x;
    my ($namelen, $namedata);
    (
        $x{parentID},
        $namelen,
        $namedata,
    )=unpack("Nna*", $_[1]);
    if (2*$namelen!=length($namedata)) {
        printf("WARN: catalogkey: len=%04x, len(namedata)=%04x\n", 2*$namelen, length($namedata));
    }
    $x{nodeName}= main::unicode2ascii($namedata);
    if ($x{nodeName} =~ /:/) { 
        printf("WARN: colon in nodename: %s\n", $x{nodeName});
    }
    $x{nodeName} =~ tr{/}{:};

    return \%x if @_==2;    # key only

    my $recordType = unpack("n", $_[2]);
    if (!exists $types{$recordType}) {
        return sprintf("unknown_%04x: %s", $recordType, unpack("H*", $_[1]));
    }

    if ($recordType<=2) {
        return $_[0]->parseFileFolder($_[2], %x);
    }
    else {
        return $_[0]->parseThread($_[2], %x);
    }
}
sub dump {
    if (!exists $_[1]{recordType}) {
        return $_[0]->dumpKey($_[1]);
    }
    elsif ($_[1]{recordType}<=2) {
        return $_[0]->dumpFileFolder($_[1]);
    }
    else {
        return $_[0]->dumpThread($_[1]);
    }
}

#size=4*32bits
sub parseBsdInfo {
    my %x;
    (
	    $x{ownerID},	#  u_int32_t 	user or group ID of file/folder owner 
	    $x{groupID},	#  u_int32_t 	additional user of group ID 
	    $x{adminFlags},	#  u_int8_t 	super-user changeable flags 
	    $x{ownerFlags},	#  u_int8_t 	owner changeable flags 
	    $x{fileMode},	#  u_int16_t 	file type and permission bits 
        $x{iNodeNum},	#  u_int32_t	indirect node number (hard links only) 
    )= unpack("NNCCnN", $_[0]);
    return \%x;
}
sub dumpBsdInfo {
    return sprintf("%08lx %5d %6d", $_[0]{fileMode}, $_[0]{ownerID}, $_[0]{groupID});
}
# size = 8*16bits
sub parseFindDirInfo {
    my %x;
    (
        $x{frRect}{top},     # folder's window rectangle
        $x{frRect}{left},
        $x{frRect}{bottom},
        $x{frRect}{right},
        $x{frFlags},        # Finder flags
        $x{frLocation}{v},   # folder's location
        $x{frLocation}{h},
        $x{opaque},
    )= unpack("nnnnnnnn", $_[0]);
    return \%x;
}
sub parseFinderOpaqueInfo {
    return $_[0];
}
sub parseForkData {
    my %x;
    (
        $x{logicalSize},
        $x{clumpSize},
        $x{totalBlocks},
        $x{extents},
    )= unpack("a8NNa*", $_[1]);
    $x{logicalSize}=main::convert64bit($x{logicalSize});

    if (length($x{extents})!=64) {
        printf("WARN: extentsdescriptor len=%d\n", length($x{extents}));
    }
    $x{extents}= [ map { parseExtentDescriptor(substr($x{extents}, 8*$_, 8)) } 0..7];

    $x{extentBlockTotal} += $_->{blockCount} for @{$x{extents}};

    for (@{$x{extents}}) {
        next if $_->{startBlock}==0 && $_->{blockCount}==0;
        printf("WARN: extent(ZERO, %d)\n", $_->{blockCount}) if ($_->{startBlock}==0);
        printf("WARN: extent(%d, ZERO)\n", $_->{startBlock}) if ($_->{blockCount}==0);
        $_[0]{bitmap}->set_range($_->{startBlock}, $_->{startBlock}+$_->{blockCount}-1) 
    }
    return \%x;
}
sub parseExtentDescriptor {
    my %extent;
    (
        $extent{startBlock},
        $extent{blockCount}
    )= unpack("NN", $_[0]);
    return \%extent;
}
sub dumpFork {
    return "" unless $_[0];
    return sprintf("%08lx#%08lx-", $_[0]{logicalSize}, $_[0]{totalBlocks}).join(",", map { sprintf("blk%08lx:%08lx", $_->{startBlock}, $_->{blockCount}) } grep { $_->{startBlock} || $_->{blockCount} }  @{$_[0]{extents}});
}
sub parseFileFolder {
    my %x=@_[2..$#_];

    (
        $x{recordType},         # int16_t          == kHFSPlusFolderRecord */
        $x{flags},              # u_int16_t        file flags */
        $x{valence},            # u_int32_t        folder's valence (limited to 2^16 in Mac OS) */
        $x{id},                 # u_int32_t        folder ID */
        $x{createDate},         # u_int32_t        date and time of creation */
        $x{contentModDate},     # u_int32_t        date and time of last content modification */
        $x{attributeModDate},   # u_int32_t        date and time of last attribute modification */
        $x{accessDate},         # u_int32_t        date and time of last access (MacOS X only) */
        $x{backupDate},         # u_int32_t        date and time of last backup */
        $x{bsdInfo},            # HFSPlusBSDInfo   permissions (for MacOS X) */
        $x{userInfo},           # FndrDirInfo      Finder information */
        $x{finderInfo},         # FndrOpaqueInfo   additional Finder information */
        $x{textEncoding},       # u_int32_t        hint for name conversions */
        $x{attrBlocks},         # u_int32_t        cached count of attribute data blocks */
        $x{dataFork},           #  HFSPlusForkData size and block data for data fork 
        $x{resourceFork},       #  HFSPlusForkData size and block data for resource fork 
    )=unpack("nnNNNNNNNa16a16a16NNa80a80", $_[1]);

    if ($x{recordType}==1) {
        $x{folderID}= $x{id};
        #$_[0]{cnidstats}[$x{folderID}] |= 1;  # folder
    }
    elsif ($x{recordType}==2) {
        $x{fileID}= $x{id};
        #$_[0]{cnidstats}[$x{fileID}] |= 2;    # file
    }
    #$_[0]{cnidstats}[$x{parentID}] |= 4;      # parent
    $x{bsdInfo}= parseBsdInfo($x{bsdInfo});
    $x{userInfo}= parseFindDirInfo($x{userInfo});
    $x{finderInfo}= parseFinderOpaqueInfo($x{finderInfo});
    $x{dataFork}= $_[0]->parseForkData($x{dataFork}) if (length $x{dataFork});
    $x{resourceFork}= $_[0]->parseForkData($x{resourceFork}) if (length $x{resourceFork});

    #use Dumpvalue;
    #Dumpvalue->new()->dumpValue(\%x);
    $_[0]->registerPath($x{id}, $x{parentID}, $x{nodeName}, $x{contentModDate}, $x{dataFork} ? $x{dataFork}{logicalSize}:-1);
    return \%x;
}
sub dumpFileFolder {
    if ($_[1]{dataFork} && $_[1]{dataFork}{extentBlockTotal}!=$_[1]{dataFork}{totalBlocks}) {
        printf("WARN: cnid%08lx: datafork calc=%08lx total=%08lx\n", $_[1]{id}, $_[1]{dataFork}{extentBlockTotal}, $_[1]{dataFork}{totalBlocks});
    }
    if ($_[1]{resourceFork} && $_[1]{resourceFork}{extentBlockTotal}!=$_[1]{resourceFork}{totalBlocks}) {
        printf("WARN: cnid%08lx: resourcefork calc=%08lx total=%08lx\n", $_[1]{id}, $_[1]{resourceFork}{extentBlockTotal}, $_[1]{resourceFork}{totalBlocks});
    }
    return sprintf("%04x %-40s cnid%08lx->cnid%08lx %s %s :: %s", $_[1]{flags}, "'".$_[1]{nodeName}."'", $_[1]{parentID}, $_[1]{id}, $types{$_[1]{recordType}}{name}, dumpFork($_[1]{dataFork}), dumpFork($_[1]{resourceFork}));
}
sub dumpKey {
    if (length $_[1]{nodeName}) {
        return sprintf("cnid%08lx:'%s'", $_[1]{parentID}, $_[1]{nodeName});
    }
    else {
        return sprintf("cnid%08lx", $_[1]{parentID});
    }
}
sub parseThread {
    my %x=@_[2..$#_];
    my ($namelen, $namedata);
    $x{id}= $x{parentID};

    if (length($x{nodeName})) {
        printf("WARN: threadkey='%s'\n", $x{nodeName});
    }

    (
        $x{recordType},     #  int16_t      == kHFSPlusFolderThreadRecord or kHFSPlusFileThreadRecord 
        $x{reserved},       #  int16_t      reserved - initialized as zero 
        $x{parentID},       #  u_int32_t    parent ID for this catalog node 
        $namelen,           #  HFSUniStr255 name of this catalog node (variable length) 
        $namedata,
    )= unpack("nnNna*", $_[1]);
    if ($x{recordType}==3) {
        $x{folderID}= $x{id};
        #$_[0]{cnidstats}[$x{folderID}] |= 8;  # threadfolder
    }
    elsif ($x{recordType}==4) {
        $x{fileID}= $x{id};
        #$_[0]{cnidstats}[$x{fileID}] |= 0x10;  # threadfile
    }
    if (2*$namelen!=length($namedata)) {
        printf("WARN: catalogthread: len=%04x, len(namedata)=%04x\n", 2*$namelen, length($namedata));
    }
    $x{nodeName}= main::unicode2ascii($namedata);
    if ($x{nodeName} =~ /:/) { 
        printf("WARN: colon in nodename: %s\n", $x{nodeName});
    }
    $x{nodeName} =~ tr{/}{:};

    #$_[0]{cnidstats}[$x{parentID}] |= 0x20;  # threadparent

    $_[0]->registerPath($x{id}, $x{parentID}, $x{nodeName});
    return \%x;
}
sub registerPath {
    my %x;
    ( $x{id}, $x{parentID}, $x{nodeName}, $x{osxmtime}, $x{size} )= @_[1..5];

    if (exists $_[0]{cnidinfo}{$x{id}}) {
        my $y= $_[0]{cnidinfo}{$x{id}};
        if ($y->{nodeName} ne $x{nodeName} || $y->{parentID} != $x{parentID}) {
            printf("WARN: cnid%08lx, 1:{cnid%08lx:'%s'}  2:{cnid%08lx:'%s'}\n",
                $x{id}, $y->{parentID}, $y->{nodeName}, $x{parentID}, $x{nodeName});
        }
        if (@_>4) {
            if (exists $y->{osxmtime} && $y->{osxmtime} != $x{osxmtime}) { printf("WARN: cnid%08lx : mtime mismatch: %08lx .. %08lx\n", $y->{osxmtime}, $x{osxmtime}); }
            if (exists $y->{size} && $y->{size} != $x{size}) { printf("WARN: cnid%08lx : filesize mismatch: %08lx .. %08lx\n", $y->{size}, $x{size}); }
            $y->{osxmtime}= $x{osxmtime} if $x{osxmtime};
            $y->{size}= $x{size} if defined $x{size};
        }
    }
    else {
        my $y = $_[0]{cnidinfo}{$x{id}}= {
            nodeName=>$x{nodeName},
            parentID=>$x{parentID},
        };
        if (@_>4) {
            $y->{osxmtime}= $x{osxmtime};
            $y->{size}= $x{size};
        }
    }
}
sub dumpThread {
    return sprintf("cnid%08lx->cnid%08lx:%s:'%s'", $_[1]{parentID}, $_[1]{id}, $types{$_[1]{recordType}}{name}, $_[1]{nodeName});
}

sub getFullPath {
    if (exists $_[0]{cnidinfo}{$_[1]}) {
        my $y=$_[0]{cnidinfo}{$_[1]};
        return $_[0]->getFullPath($y->{parentID}).'/'.$y->{nodeName};
    }
    elsif ($_[1]==1) {
        return "";
    }
    else {
        return sprintf("cnid%08lx", $_[1]);
    }
}
sub getFileSize {
    if (exists $_[0]{cnidinfo}{$_[1]}) {
        return $_[0]{cnidinfo}{$_[1]}{size};
    }
    else {
        return -1;
    }
}
sub getFileDate {
    if (exists $_[0]{cnidinfo}{$_[1]}) {
        return datestring($_[0]{cnidinfo}{$_[1]}{osxmtime});
    }
    else {
        return "?";
    }
}
# 01  folder
# 02  file
# 04  ff-parent
# 08  t-folder
# 10  t-file
# 20  t-parent
sub dumpStatsX {
    for (my $nr=0 ; $nr<@{$_[0]{cnidstats}} ; $nr++) {
        if (defined $_[0]{cnidstats}[$nr]) {
            printf("cnid%08lx: usage: %06b  %10d %-20s %s\n", $nr, $_[0]{cnidstats}[$nr], 
                $_[0]->getFileSize($nr), $_[0]->getFileDate($nr), $_[0]->getFullPath($nr));
        }
    }
}
sub dumpStats {
    while (my ($nr, $val)=each %{$_[0]{cnidinfo}}) {
        #printf("%s\n", join(",", map { "$_ => $val->{$_}" } keys %$val));
        printf("cnid%08lx:  %10d %-20s %s\n", $nr, 
            exists $val->{size} ? $val->{size} : -1, datestring($val->{osxmtime}), $_[0]->getFullPath($nr));
    }
}
sub getBlockBitmap {
    return $_[0]{bitmap};
}
1;
