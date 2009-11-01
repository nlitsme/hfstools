#!perl -w
use strict;
use POSIX;
sub parsedate {
    my @f= map { s/\.\./0/; $_ } split /[- :]/, $_[0];
    $f[0]-=1900;
    $f[1]-=1;
    my $t= POSIX::mktime  reverse @f;
    if (!defined $t) {
        printf("error parsing date: %s\n", $_[0]);
    }
    return $t;
}
sub datestring {
    return POSIX::strftime "%Y-%m-%d %H:%M:%S", localtime $_[0];
}
sub unescapename {
    my $n= shift;
# { 0xc2,0xae} = 11 000010 10 101110  = 000010 101110 = 0xae

    $n =~ s/\\ / /g;
    $n =~ s/\\r/\r/g;
    $n =~ s/\\3(\d{2}(?:\\2\d{2})+)/chr(oct(join("",split m{\\2}, $1)))/ge;
    return $n;
}
sub readlist {
    my $fn=shift;
    my @list;
    open FH, "<$fn" or die "$fn:$!\n";
    while (<FH>) {
        s/\s+$//;
        if (/^\s*(\S+)\s(\S+\s\S+)\s+(.*)/) {
            push @list, [$1,parsedate($2),unescapename($3)];
        }
    }
    close FH;
    return @list;
}

my @bk= sort { $a->[2] cmp $b->[2] } grep { $_->[2] =~ s{itsmehome/itsme/}{} } readlist("ls-lr-itsmehome");
my @osx= sort { $a->[2] cmp $b->[2] } grep { $_->[2] =~ s{^/Macintosh HD/Users/itsme/}{} } readlist("ls-lr-machd-before-crash");

my ($i,$j)=(0,0);
while ($i<@bk && $j<@osx) {
    while ($i<@bk && $bk[$i][2] lt $osx[$j][2]) {
        printf("- %10d %20s %10s %20s - %s\n", $bk[$i][0], datestring($bk[$i][1]), "", "", , $bk[$i][2]);
        $i++;
    }
    last unless ($i<@bk && $j<@osx);
    if ($bk[$i][2] eq $osx[$j][2]) {
        writediff($bk[$i], $osx[$j]);
    }
    $i++; $j++;
    last unless ($i<@bk && $j<@osx);
    while ($j<@osx && $bk[$i][2] gt $osx[$j][2]) {
        printf("+ %10s %20s %10d %20s + %s\n", "", "", $osx[$j][0], datestring($osx[$j][1]), , $osx[$j][2]);
        $j++;
    }
    last unless ($i<@bk && $j<@osx);
    if ($bk[$i][2] eq $osx[$j][2]) {
        writediff($bk[$i], $osx[$j]);
    }
    $i++; $j++;
}
sub comparesize {
    return 1 if $_[0]==-1;
    return 1 if $_[1]==-1;
    return 1 if $_[1]==$_[0];
}
sub comparedate {
    return 1 unless $a->[1] && $b->[1];
    return 0 if ($a->[1]-$b->[1])<-86400;
    return 0 if ($a->[1]-$b->[1])>86400;
    return 1;
}
sub writediff {
    my ($a,$b)=@_;
    if (!comparesize($a->[0], $b->[0]) || !comparedate($a->[1], $b->[1])) {
        printf("! %10d %20s %10d %20s ! %s\n", $a->[0], datestring($a->[1]), $b->[0], datestring($b->[1]), $a->[2]);
    }
}
