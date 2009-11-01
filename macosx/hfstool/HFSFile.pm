#!perl -w

# NOTE: this is an unfinished module

package HFSFile;
use strict;
sub open {
    my $fh;
    tie $fh, "HFSFile";
    $fh->open(@_);
    return $fh;
}
sub TIEHANDLE {
    my ($class, $volume)= @_;
    return bless {
        volume=>$volume,
    }, shift
}
sub OPEN  {
}
sub READ  {
    my $class=shift;
    my $into = \$_[0]; shift;
}
sub READLINE  {
}
sub GETC  {
}
#sub WRITE  { }
#sub PRINT  { }
#sub PRINTF  { }
#sub BINMODE  { }
#sub FILENO  { }
sub EOF  {
}
sub SEEK  {
}
sub TELL  {
}
sub CLOSE  {
}
sub DESTROY  {
}
sub UNTIE  {
}

