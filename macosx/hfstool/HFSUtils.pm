#!perl -w
package HFSUtils;
use strict;
use Exporter;
use POSIX;
our @ISA=qw(Exporter);
our @EXPORT=qw(unicode2ascii convert64bit datestring);

sub unicode2ascii {
    pack 'C*', map { $_>255 ? 0x7e:$_ } unpack 'n*', $_[0];
}
sub convert64bit {
    my @x= unpack("NN", $_[0]);
    return $x[0]*(2**32)+$x[1];
}
sub datestring {
    my $osxdate= shift;
    return "" unless $osxdate;
    # 7C25B080  is the nr of seconds between 1904-1-1  and 1970-1-1
    #return POSIX::strftime("%F %T", gmtime $osxdate-0x7C25B080);
    return POSIX::strftime("%Y-%m-%d %H:%M:%S", gmtime $osxdate-0x7C25B080);
}
