package Bitmap;
use strict;
use warnings;
use Carp;
sub new {
    my $a= (@_>1) ? $_[1] : "";
    return bless \$a, $_[0];
}

sub set {
    vec(${$_[0]}, ($_[1]&~7)+(7-($_[1]&7)), 1)=1;
}
sub test {
    return vec(${$_[0]}, ($_[1]&~7)+(7-($_[1]&7)), 1);
}
sub size {
    return 8*length(${$_[0]});
}
# sets inclusive range:  $bitmap->set_range(first, last)
sub set_range {
    my $bit;
    if ($_[1]&7) {
        for ($bit=$_[1] ; $bit < ($_[1]|7)+1 && $bit <= $_[2] ; $bit++)
        {
            $_[0]->set($bit);
        }
    }
    else {
        $bit=$_[1];
    }
    my $last;
    if (($_[2]&7)!=7) {
        for ($last=$_[2] ; $last >= ($_[2]&~7) && $last >=$_[1] ; $last--)
        {
            $_[0]->set($last);
        }
    }
    else {
        $last=$_[2];
        $_[0]->set($last);
    }
    if ($bit < $last) {
        substr(${$_[0]}, $bit/8, ($last+1-$bit)/8) = "\xff" x (($last+1-$bit)/8);
    }
#    $_[0]->set($_) for ($_[1]..$_[2]);
}
sub load {
    my $bitmapfile= $_[1];
    local $/;
    open BM, "<$bitmapfile" or croak "$bitmapfile:$!\n";
    binmode BM;
    ${$_[0]} = <BM>;
    close BM;
}
sub readfromhandle {
    my $hbitmap= $_[1];
    $hbitmap->seek(0, 0);
    my $ofs=0;
    while (!$hbitmap->eof()) {
        my $data;
        $hbitmap->read($data, 0x100000);
        substr(${$_[0]}, $ofs, length($data))= $data;
        $ofs += length($data);
    }
}
sub save {
    my $bitmapfile= $_[1];
    open BM, ">$bitmapfile" or croak "$bitmapfile:$!\n";
    binmode BM;
    print BM  ${$_[0]};
    close BM;
}
sub setblock { substr(${$_[0]}, $_[1], length($_[2]))= $_[2]; }
sub xor { return Bitmap->new(${$_[0]} ^ ${$_[1]}); }
sub  or { return Bitmap->new(${$_[0]} | ${$_[1]}); }
sub and { return Bitmap->new(${$_[0]} & ${$_[1]}); }
sub clear { return Bitmap->new(${$_[0]} & ~${$_[1]}); }

sub negate { ${$_[0]} = ~${$_[0]}; }
sub add { ${$_[0]} |= ${$_[1]}; }

# todo:
#   - add total calc
#   - add skip \xff+  sequences
sub dump {
    my $start;
    my $notfirst;
    for (my $bit=0 ; $bit<$_[0]->size() ; $bit++) {
        if (($bit&7)==0) {
            # skip to next non-nul byte
            pos(${$_[0]})=$bit/8;
            if (defined $start) {
                if (${$_[0]}=~ /\G\xFF+/g) {
                    $bit=pos(${$_[0]})*8;
                }
            }
            else {
                if (${$_[0]}=~ /\G\x00+/g) {
                    $bit=pos(${$_[0]})*8;
                }
            }
        }
        if ($_[0]->test($bit)) {
            if (!defined $start) {
                $start= $bit;
            }
        }
        else {
            if (defined $start) {
                printf(", ") if ($notfirst);
                $notfirst=1;
                if ($start==$bit-1) {
                    printf("%08x", $start);
                }
                else {
                    printf("%08x-%08x", $start, $bit-1);
                }
            }
            undef $start;
        }
    }
}
# todo: implement range_iterate
1;
