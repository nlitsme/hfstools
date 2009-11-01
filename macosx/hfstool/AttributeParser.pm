package AttributeParser;
use strict;
use warnings;

sub new { return bless {}, $_[0]; }
sub parse {
    my %x;
    my ($namelen, $namedata);
    (
        $x{pad},
        $x{fileid},
        $x{startBlock},
        $namelen,
        $namedata,
    )= unpack("nNNna*", $_[1]);
    if (2*$namelen!=length($namedata)) {
        printf("WARN: attributekey: len=%04x, len(namedata)=%04x\n", 2*$namelen, length($namedata));
    }
    $x{name}= main::unicode2ascii($namedata);

    return \%x if @_==2;    # key only

    my $datalen;
    (
        $x{recordType},
        undef,
        undef,
        $datalen,
        $x{data},
    )= unpack("NNNNa*", $_[2]);
    if ($datalen==length($x{data})-1) {
        $x{data}= substr($x{data},0,$datalen);
    }
    elsif (length($x{data})!=$datalen) {
        printf("WARN: attributevalue: len=%04x, len(data)=%04x\n", $datalen, length($x{data}));
    }
    return \%x;
}
sub dump {
    if (exists $_[1]{recordType})  {
        return sprintf("cnid%08lx:%-40s => %08lx:%s", $_[1]{fileid}, "'".$_[1]{name}."'", $_[1]{recordType},
            ($_[1]{data} =~ /^[\x20-\x7e]{20}/) ? "'".$_[1]{data}."'" : unpack('H*', $_[1]{data}) );
    }
    else {
        return sprintf("cnid%08lx:%08lx:%s", $_[1]{fileid}, $_[1]{startBlock}, "'".$_[1]{name}."'");
    }
}
sub dumpStats {
    
}
1;
