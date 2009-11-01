package HFSForkData;
use strict;
use warnings;
use HFSUtils;
use Fcntl qw(:seek);
use Carp;

# NOTE: you cannot use {volume} in the constructor, since this object is
#  called from the volume constructor.

# this object is meant to be used as an alternative to IO::File by HFSBtree.

sub new {
    my ($class, $volume, $cnid, $forkdata)= @_;

    my $self= bless {
        volume=>$volume,
        cnid=>$cnid,
        forkdata=>parseForkData($forkdata),
        cur=>[0,0,0,0],
    }, $class;

    return $self;
}
sub read {
    my $self=shift;

    my $cur= $self->{cur};
    my $ext= $self->{forkdata}{extents};
    my $size= $_[1];
    my $pos= $_[2];
    #printf("fork-read(%08lx, %08lx)\n", $size, @_>2 ? $pos : 0);
    my $bytesread=0;
    while ($bytesread < $size) {
        my $chunksize= $self->getcurextsize($self->{cur});
        $chunksize= $size if $chunksize>$size;
        my $nblocks= int($chunksize/$self->{volume}->blocksize())+($chunksize%$self->{volume}->blocksize())?1:0;

        my $data= substr($self->{volume}->readblock($ext->[$cur->[1]]{startBlock}+$cur->[2], $nblocks), $cur->[3], $chunksize);

        if (@_ > 2) { # read offset
            substr($_[0],$pos+$bytesread) = $data;
        }
        else {
            $_[0] .= $data;
        }

        $cur=$self->{cur} = $self->incrementoffset($self->{cur}, length($data));
        $bytesread += length($data);
    }
    #printf("bytesread: %d\n", $bytesread);
    return 1;
}
sub save {
    my ($self,$name)=@_;
    open OUT, ">$name" or die "$name:$!\n";
    binmode OUT;
    $self->seek(0, SEEK_SET);

    while (!$self->eof())
    {
        my $data;
        $self->read($data, 0x100000);
        print OUT $data;
    }
    close OUT;
}
sub eof  {
    my $self=shift;

    return !$self->{cur} || ($self->{cur}[0] >= $self->{forkdata}{logicalSize}) || ($self->{cur}[0]<0);
}
sub seek  {
    my $self=shift;
    my $distance=shift;
    my $method=shift;
    if ($method==SEEK_SET) {
        $self->{cur} = $self->findoffset($distance);
    }
    elsif ($method==SEEK_CUR) {
        $self->{cur} = $self->incrementoffset($self->{cur}, $distance);
    }
    elsif ($method==SEEK_END) {
        warn "cannot seek from end\n";
        return undef;
    }
    return 1;
}
sub tell  {
    my $self=shift;
    return $self->{cur}[0];
}

sub parseForkData {
    my %x;
    (
        $x{logicalSize},
        $x{clumpSize},
        $x{totalBlocks},
        $x{extents},
    )= unpack("a8NNa64", $_[0]);

    $x{logicalSize}= convert64bit($x{logicalSize});

    # strip NUL extents
    $x{extents} =~ s/(?:\x00{8})+$//;

    $x{extents}= [ map { parseExtentDescriptor(substr($x{extents}, 8*$_, 8)) } 0..length($x{extents})/8-1 ];

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
    return sprintf("%08lx#%08lx-", $_[0]{forkdata}{logicalSize}, $_[0]{forkdata}{totalBlocks}).join(",", map { sprintf("blk%08lx:%08lx", $_->{startBlock}, $_->{blockCount}) } @{$_[0]{extents}});
}
sub checkOverflowExtents {
    my $self=shift;

    # todo: search overflow file for
    # [cnid, extent_blocks], and add to forkdata.extents
    return;
}
# functions for manipulating extent-offsets
sub findoffset {
    my $self=shift;
    my $ofs=shift;

    my $extidx=0;
    my $cur=0;
    while ($extidx<@{$self->{forkdata}{extents}}) {
        if ($cur<=$ofs && $ofs<$cur+$self->{forkdata}{extents}[$extidx]{blockCount}*$self->{volume}->blocksize()) {
            return [$ofs, $extidx, int(($ofs-$cur)/$self->{volume}->blocksize()), ($ofs-$cur) % $self->{volume}->blocksize()];
        }
        $cur += $self->{forkdata}{extents}[$extidx]{blockCount}*$self->{volume}->blocksize();
        $extidx++;
        if ($extidx==@{$self->{forkdata}{extents}}) {
            $self->checkOverflowExtents();
        }
    }
    printf("%08lx: not found\n", $ofs);
    return;
}
sub incrementoffset {
    my $self=shift;
    return unless $_[0];
    my ($ofs, $ei, $bi, $bofs)= @{$_[0]};
    my $increment=@_>1 ? $_[1] : 1;
    $bofs += $increment;
    $ofs += $increment;
    if ($bofs>=$self->{volume}->blocksize()) {
        $increment=int($bofs/$self->{volume}->blocksize());
        $bofs=$bofs % $self->{volume}->blocksize();

        $bi += $increment;
        while ($bi>=$self->{forkdata}{extents}[$ei]{blockCount}) {
            $bi-=$self->{forkdata}{extents}[$ei]{blockCount};
            $ei++;
            if ($ei>=@{$self->{forkdata}{extents}}) {
                if (!$self->checkOverflowExtents()) {
                    printf("EOF\n");
                    return;
                }
            }
        }
    }
    return [$ofs, $ei,$bi,$bofs];
}
sub getcurextsize {
    my $self=shift;
    return unless @_ && $_[0];
    my ($ofs, $ei, $bi, $bofs)= @{$_[0]};
    return $self->{volume}->blocksize()*($self->{forkdata}{extents}[$ei]{blockCount}-$bi)-$bofs;
}
sub dumpofs {
    my $self=shift;
    return unless @_ && $_[0];
    printf("%08lx: ei=%d bi=%d ofs=%04x  extsize=%x\n", @{$_[0]}, $self->getcurextsize(@_));
}

sub calc_alloc_bitmap {
    my $self=shift;
    my $bitmap= Bitmap->new();
    for (@{$self->{forkdata}{extents}}) {
        $bitmap->set_range($_->{startBlock}, $_->{startBlock}+$_->{blockCount}-1);
    }
    return $bitmap;
}
1;
