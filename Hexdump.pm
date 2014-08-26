package Hexdump;
use strict;
use warnings;
use Exporter;
our @ISA=qw(Exporter);
use Carp;

our @EXPORT=qw(hexdump ascdump);
sub hexbytes {
    my $str= unpack("H*", $_[0]);
    $str =~ s/\w\w/$& /g;
    $str =~ s/ $//;
    return $str;
}
sub ascbytes {
    my $str= $_[0];
    $str =~ s/[^ -~]/./g;
    return $str;
}
sub hexdump {
    my @lines;
    my $same;
    my $ofs=$_[1] || 0;
    push @lines, sprintf("%s  %s", hexbytes(substr($_[0],$_*16,16)), ascbytes(substr($_[0],$_*16,16))) for 0..length($_[0])/16-1;
    for (0..$#lines) {
        if ($_ && $lines[$_-1] eq $lines[$_]) {
            if (!$same) {
                printf("*\n");
            }
            $same=1;
        }
        else {
            printf("%04x: %s\n", $ofs+$_*16, $lines[$_]);
            $same=0;
        }
    }
}
sub ascdump {
    my $ofs= $_[1] || 0;
    my %esc= (
        "\n"=>'n',
        "\r"=>'r',
        "\t"=>'t',
        "\n"=>'n',
        "\0"=>'0',
        "\\"=>'\\',
    );
    my $pos;
    while ($_[0] =~ /.*?[\r\n\x00]+/gs) {
        my $line= $&;
        my $epos= pos($_[0]);
        my $len= length($line);
        my $spos= $epos-$len;
        if ($spos!=$pos) {
            printf("W: %x!=%x\n", $spos, $pos);
        }

        $line =~ s/./exists $esc{$&}?"\\$esc{$&}":$&/gse;
        printf("%04x: %s\n", $ofs+$spos, $line);
        $pos= $epos;
    }
    my $line= substr($_[0], $pos);
    $line =~ s/./exists $esc{$&}?"\\$esc{$&}":$&/gse;
    printf("%04x: %s\n", $ofs+$pos, $line);
}
1;
