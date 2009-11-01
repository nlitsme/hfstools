#!perl
use strict;
use warnings;
use Bitmap;
for (shift) {
    if (/^xor$/) {
        my $a= Bitmap->new(); $a->load(shift);
        my $b= Bitmap->new(); $b->load(shift);
        my $c= $a->xor($b);
        if (@ARGV) {
            $c->save(shift);
        }
        else {
            $c->dump();
        }
    }
    if (/^and$/) {
        my $a= Bitmap->new(); $a->load(shift);
        my $b= Bitmap->new(); $b->load(shift);
        my $c= $a->and($b);
        if (@ARGV) {
            $c->save(shift);
        }
        else {
            $c->dump();
        }
    }
    if (/^clear$/) {
        my $a= Bitmap->new(); $a->load(shift);
        my $b= Bitmap->new(); $b->load(shift);
        my $c= $a->clear($b);
        if (@ARGV) {
            $c->save(shift);
        }
        else {
            $c->dump();
        }
    }
    if (/^or$/) {
        my $a= Bitmap->new(); $a->load(shift);
        my $b= Bitmap->new(); $b->load(shift);
        my $c= $a->or($b);
        if (@ARGV) {
            $c->save(shift);
        }
        else {
            $c->dump();
        }
    }
    if (/^diff$/) {
        my $a= Bitmap->new(); $a->load(shift);
        my $b= Bitmap->new(); $b->load(shift);
        my $a_b= $a->clear($b);
        my $b_a= $b->clear($a);
        printf("a minus b\n");
        $a_b->dump();
        printf("\nb minus a\n");
        $b_a->dump();
    }
    if (/^dump$/) {
        my $a= Bitmap->new(); $a->load(shift);
        $a->dump();
    }
    if (/^dumpnul$/) {
        my $a= Bitmap->new(); $a->load(shift);
        $a->negate();
        $a->dump();
    }
}
