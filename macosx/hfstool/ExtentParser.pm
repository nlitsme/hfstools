package ExtentParser;
use strict;
use warnings;

sub new { return bless { bitmap=>Bitmap->new() }, $_[0]; }
sub parse {
    my %x;
    (
        $x{forkType},
        $x{pad},
        $x{fileID},
        $x{startBlock},
    )= unpack("CCNN", $_[1]);

    return \%x if @_==2;    # key only

    $x{extents}= [ map { CatalogParser::parseExtentDescriptor(substr($_[2], 8*$_,8)) } 0..7 ];
    $_[0]{stats}[$x{fileID}] += $_->{blockCount} for @{$x{extents}};

    for (@{$x{extents}}) {
        next if $_->{startBlock}==0 && $_->{blockCount}==0;
        printf("WARN: extent(ZERO, %d)\n", $_->{blockCount}) if ($_->{startBlock}==0);
        printf("WARN: extent(%d, ZERO)\n", $_->{startBlock}) if ($_->{blockCount}==0);
        $_[0]{bitmap}->set_range($_->{startBlock}, $_->{startBlock}+$_->{blockCount}-1) 
    }

    return \%x;
}
sub dump {
    if (exists $_[1]{extents}) {
        return sprintf("%02x cnid%08lx:%08lx => %s", $_[1]{forkType}, $_[1]{fileID}, $_[1]{startBlock},
            join(",", map { sprintf("blk%08lx:%08lx", $_->{startBlock}, $_->{blockCount}) } grep { $_->{startBlock} || $_->{blockCount} }  @{$_[1]{extents}}));
    }
    else {
        return sprintf("%02x cnid%08lx:%08lx", $_[1]{forkType}, $_[1]{fileID}, $_[1]{startBlock});
    }
}
sub dumpStats {
    for (my $nr=0 ; $nr<@{$_[0]{stats}} ; $nr++) {
        if (defined $_[0]{stats}[$nr]) {
            printf("cnid%08lx: total %08x blocks\n", $nr, $_[0]{stats}[$nr]);
        }
    }

}
sub getBlockBitmap {
    return $_[0]{bitmap};
}
1;
