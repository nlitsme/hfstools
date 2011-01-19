#!perl -w
use strict;
$|=1;
# see http://developer.apple.com/technotes/tn/tn1150.html
# or http://fxr.watson.org/fxr/source/bsd/hfs/hfs_format.h?v=xnu-792
sub opendisk {
    open HD, '</dev/rdisk0s2' or die qq(rdisk0s2: $!);
    binmode HD;
}
sub closedisk {
    close HD;
}
sub readSector {
    my ($sectornr, $n)= @_;
    $n=1 unless defined $n;
    return "" if $n==0;
    sysseek(HD, $sectornr*0x200, 0) or die "invalid sector $sectornr";
    my $data;
    sysread(HD,$data,0x200*$n) or die "error reading sector $sectornr";
    return $data;
}
my %tests= (
"\x00\x00\xc6\x60\x00\x00\xc3\x61"=>0x000003, #  \x00\x02
"\x00\x00\xdf\x6c\x00\x00\xdf\x68"=>0x00e001, #  \xff\x01
"\x00\x00\xdf\xfe\x00\x00\xdf\xfb"=>0x00e00e, #  \xff\x01
"\x00\x00\xdf\xf8\x00\x00\xdf\xc8"=>0x00e013, #  \xff\x01
"\x00\x00\xdf\xf4\x00\x00\xdf\xf1"=>0x00e015, #  \xff\x01
"\x00\x00\xdf\xe9\x00\x00\xdf\xf2"=>0x00e016, #  \xff\x01
"\x00\x00\xdf\xd8\x00\x00\xdf\xd4"=>0x00e017, #  \xff\x01
"\x00\x00\xdf\xe0\x00\x00\xdf\xdd"=>0x00e019, #  \xff\x01
"\x00\x00\xdf\x90\x00\x00\xdf\x8e"=>0x00e01e, #  \xff\x01
"\x00\x00\xdf\xe4\x00\x00\xdf\x91"=>0x00e025, #  \xff\x01
"\x00\x00\xdf\x98\x00\x00\xdf\x9a"=>0x00e02d, #  \xff\x01
"\x00\x00\xdf\x9c\x00\x00\xdf\x9b"=>0x00e036, #  \xff\x01
"\x00\x00\xdf\xa8\x00\x00\xdf\xa7"=>0x00e037, #  \xff\x01
"\x00\x00\xdf\xa2\x00\x00\xdf\x9f"=>0x00e040, #  \xff\x01
"\x00\x00\xdf\xa7\x00\x00\xdf\xa6"=>0x00e04e, #  \xff\x01
"\x00\x00\xdf\xa9\x00\x00\xdf\xa0"=>0x00e055, #  \xff\x01
"\x00\x00\xc9\x06\x00\x00\xc9\x05"=>0x00e05a, #  \xff\x01
"\x00\x00\xdf\xb0\x00\x00\xdf\xac"=>0x00e05e, #  \xff\x01
"\x00\x00\xdf\xaf\x00\x00\xdf\xad"=>0x00e060, #  \xff\x01
"\x00\x00\xce\xe8\x00\x00\xcd\x95"=>0x00e06c, #  \xff\x01
"\x00\x00\xdf\xb6\x00\x00\xdf\xb5"=>0x00e06e, #  \xff\x01
"\x00\x00\xcd\x96\x00\x00\xce\xeb"=>0x00e06f, #  \xff\x01
"\x00\x00\xcd\x71\x00\x00\xcd\x70"=>0x00e070, #  \xff\x01
"\x00\x00\xce\xf0\x00\x00\xcd\x71"=>0x00e073, #  \xff\x01
"\x00\x00\xce\xf3\x00\x00\xce\x19"=>0x00e079, #  \xff\x01
"\x00\x00\xcd\x9a\x00\x00\xce\xf5"=>0x00e07b, #  \xff\x01
"\x00\x00\xdf\xbb\x00\x00\xdf\xba"=>0x00e07c, #  \xff\x01
"\x00\x00\xce\xf8\x00\x00\xce\xf7"=>0x00e07d, #  \xff\x01
"\x00\x00\xcd\x7a\x00\x00\xce\xf6"=>0x00e07f, #  \xff\x01
"\x00\x00\xce\xfd\x00\x00\xce\xfc"=>0x00e080, #  \xff\x01
"\x00\x00\xcf\x00\x00\x00\xce\xff"=>0x00e083, #  \xff\x01
"\x00\x00\xdf\xbf\x00\x00\xdf\xbe"=>0x00e084, #  \xff\x01
"\x00\x00\xcf\x02\x00\x00\xcd\x7f"=>0x00e088, #  \xff\x01
"\x00\x00\xcd\x88\x00\x00\xcd\x80"=>0x00e08a, #  \xff\x01
"\x00\x00\xdf\xc2\x00\x00\xdf\xc0"=>0x00e08d, #  \xff\x01
"\x00\x00\xcd\x9e\x00\x00\xde\x86"=>0x00e08f, #  \xff\x01
"\x00\x00\xcf\x06\x00\x00\xcd\x90"=>0x00e090, #  \xff\x01
"\x00\x00\xd2\x7e\x00\x00\xd2\x7d"=>0x00e0d3, #  \xff\x01
"\x00\x00\xd2\x7d\x00\x00\xd2\x7b"=>0x00e0d6, #  \xff\x01
"\x00\x00\xcd\xf4\x00\x00\xc9\x03"=>0x00e114, #  \xff\x01
"\x00\x00\xcc\xa9\x00\x00\xc9\x04"=>0x00e131, #  \xff\x01
"\x00\x00\xce\xe5\x00\x00\xdd\x32"=>0x00e132, #  \xff\x01
"\x00\x00\xdf\x58\x00\x00\xdf\x2b"=>0x00e144, #  \x00\x02
"\x00\x00\xdc\xe7\x00\x00\xdc\xe2"=>0x00e176, #  \xff\x01
"\x00\x00\xdd\x47\x00\x00\xdc\xe5"=>0x00e179, #  \xff\x01
"\x00\x00\xce\x0f\x00\x00\xce\x11"=>0x00e17a, #  \xff\x01
"\x00\x00\xd2\x96\x00\x00\xce\x10"=>0x00e17c, #  \xff\x01
"\x00\x00\xdd\x4c\x00\x00\xdc\xea"=>0x00e17f, #  \xff\x01
"\x00\x00\xdd\x4e\x00\x00\xdd\x4c"=>0x00e181, #  \xff\x01
"\x00\x00\xce\x15\x00\x00\xce\x13"=>0x00e182, #  \xff\x01
"\x00\x00\xdc\xbd\x00\x00\xdd\x4e"=>0x00e186, #  \xff\x01
"\x00\x00\xce\x16\x00\x00\xd2\x98"=>0x00e187, #  \xff\x01
"\x00\x00\xd2\x7b\x00\x00\xd2\x7a"=>0x00e18a, #  \xff\x01
"\x00\x00\xd2\x79\x00\x00\xd2\x78"=>0x00e192, #  \xff\x01
"\x00\x00\xd2\x77\x00\x00\xd2\x76"=>0x00e19a, #  \xff\x01
"\x00\x00\xd2\x76\x00\x00\xd2\x75"=>0x00e19d, #  \xff\x01
"\x00\x00\xd2\x75\x00\x00\xd2\x71"=>0x00e1a7, #  \xff\x01
"\x00\x00\xc9\x03\x00\x00\xcb\x32"=>0x00e1b8, #  \xff\x01
"\x00\x00\xc9\x08\x00\x00\xdc\xc3"=>0x00e1b9, #  \xff\x01
"\x00\x00\xd2\x6a\x00\x00\xd2\x69"=>0x00e1dc, #  \xff\x01
"\x00\x00\xd1\xcb\x00\x00\xd1\xc9"=>0x00e1fa, #  \xff\x01
"\x00\x00\xd1\xca\x00\x00\xd1\xc7"=>0x00e202, #  \xff\x01
"\x00\x00\xd1\xc7\x00\x00\xd1\xc6"=>0x00e206, #  \xff\x01
"\x00\x00\xd1\xc6\x00\x00\xd1\xc3"=>0x00e20a, #  \xff\x01
"\x00\x00\xd1\xbf\x00\x00\xd1\xbc"=>0x00e21e, #  \xff\x01
"\x00\x00\xd1\xba\x00\x00\xd1\xb9"=>0x00e229, #  \xff\x01
"\x00\x00\xd1\x41\x00\x00\xd1\x40"=>0x00e257, #  \xff\x01
"\x00\x00\xd1\x40\x00\x00\xd1\x3f"=>0x00e25b, #  \xff\x01
"\x00\x00\xd1\x3b\x00\x00\xd1\x3a"=>0x00e26a, #  \xff\x01
"\x00\x00\xd1\x38\x00\x00\xd1\x36"=>0x00e274, #  \xff\x01
"\x00\x00\xd1\x27\x00\x00\xd1\x26"=>0x00e291, #  \xff\x01
"\x00\x00\xd1\x26\x00\x00\xd1\x25"=>0x00e294, #  \xff\x01
"\x00\x00\xd1\x21\x00\x00\xd1\x1f"=>0x00e2a0, #  \xff\x01
"\x00\x00\xd1\x1a\x00\x00\xd1\x19"=>0x00e2ad, #  \xff\x01
"\x00\x00\xd1\x19\x00\x00\xd1\x18"=>0x00e2b1, #  \xff\x01
"\x00\x00\xc1\x42\x00\x00\x5d\x0e"=>0x00e2ba, #  \xff\x01
"\x00\x00\x5d\x0e\x00\x00\x5c\x47"=>0x00e2be, #  \xff\x01
"\x00\x00\x5c\x47\x00\x00\x5c\x31"=>0x00e2c2, #  \xff\x01
"\x00\x00\x5c\x2b\x00\x00\x5c\x29"=>0x00e2ce, #  \xff\x01
"\x00\x00\x3d\x79\x00\x00\x3d\x78"=>0x00e2de, #  \xff\x01
"\x00\x00\xc2\x7d\x00\x00\xd6\x3e"=>0x00e3a1, #  \xff\x01
"\x00\x00\xc2\x7c\x00\x00\x58\x50"=>0x00e3c7, #  \xff\x01
"\x00\x00\xd6\x47\x00\x00\x5c\x32"=>0x00e42a, #  \xff\x01
"\x00\x00\xd6\x4c\x00\x00\xd6\x4e"=>0x00e440, #  \xff\x01
);
opendisk();
for (my $n=0 ; $n<0x1600000 ; $n++) {
    my $sect= readSector($n*8);
    my $s8= substr($sect,0,8);
    if (exists $tests{$s8}) {
        printf("block %08lx: found node %08lx: %s\n", $n, $tests{$s8}, unpack("H*", substr($sect, 0, 16)));
    }
    if (!($n&0xfff)) {
        printf("%08lx\r", $n);
    }
}

__END__
block 00000d07: found node 00000003: 0000c6600000c361000200d900000006
block 001ff1a3: found node 0000e001: 0000df6c0000df68ff01002d00000006
block 001ff1bd: found node 0000e00e: 0000dffe0000dffbff01000f0000001e
block 001ff1c7: found node 0000e013: 0000dff80000dfc8ff0100100000001e
block 001ff1cb: found node 0000e015: 0000dff40000dff1ff01000f0000001e
block 001ff1cd: found node 0000e016: 0000dfe90000dff2ff01001700000024
block 001ff1cf: found node 0000e017: 0000dfd80000dfd4ff0100100000001e
block 001ff1d3: found node 0000e019: 0000dfe00000dfddff01000f0000001e
block 001ff1dd: found node 0000e01e: 0000df900000df8eff01002b00000006
block 001ff1eb: found node 0000e025: 0000dfe40000df91ff01001c0000001a
block 001ff1fb: found node 0000e02d: 0000df980000df9aff01001600000020
block 001ff20d: found node 0000e036: 0000df9c0000df9bff01001900000006
block 001ff20f: found node 0000e037: 0000dfa80000dfa7ff01000800000016
block 001ff221: found node 0000e040: 0000dfa20000df9fff01001d0000001c
block 001ff23d: found node 0000e04e: 0000dfa70000dfa6ff0100100000001c
block 001ff24b: found node 0000e055: 0000dfa90000dfa0ff01005a00000006
block 001ff255: found node 0000e05a: 0000c9060000c905ff01001600000006
block 001ff25d: found node 0000e05e: 0000dfb00000dfacff01000700000006
block 001ff261: found node 0000e060: 0000dfaf0000dfadff01001c0000001e
block 001ff279: found node 0000e06c: 0000cee80000cd95ff0100100000001e
block 001ff27d: found node 0000e06e: 0000dfb60000dfb5ff01000e0000001c
block 001ff27f: found node 0000e06f: 0000cd960000ceebff01000e0000003e
block 001ff281: found node 0000e070: 0000cd710000cd70ff0100130000002c
block 001ff287: found node 0000e073: 0000cef00000cd71ff01000e0000002c
block 001ff293: found node 0000e079: 0000cef30000ce19ff01001b0000002a
block 001ff297: found node 0000e07b: 0000cd9a0000cef5ff01000f00000020
block 001ff299: found node 0000e07c: 0000dfbb0000dfbaff01000e0000002e
block 001ff29b: found node 0000e07d: 0000cef80000cef7ff0100100000001e
block 001ff29f: found node 0000e07f: 0000cd7a0000cef6ff01001a00000020
block 001ff2a1: found node 0000e080: 0000cefd0000cefcff0100100000001a
block 001ff2a7: found node 0000e083: 0000cf000000ceffff01000f00000026
block 001ff2a9: found node 0000e084: 0000dfbf0000dfbeff01000f00000036
block 001ff2b1: found node 0000e088: 0000cf020000cd7fff01001000000034
block 001ff2b5: found node 0000e08a: 0000cd880000cd80ff01000f00000030
block 001ff2bb: found node 0000e08d: 0000dfc20000dfc0ff01000f00000020
block 001ff2bf: found node 0000e08f: 0000cd9e0000de86ff01000e00000028
block 001ff2c1: found node 0000e090: 0000cf060000cd90ff01001200000026
block 001ff347: found node 0000e0d3: 0000d27e0000d27dff01000b00000006
block 001ff34d: found node 0000e0d6: 0000d27d0000d27bff01000d00000006
block 001ff3c9: found node 0000e114: 0000cdf40000c903ff0100140000001a
block 001ff403: found node 0000e131: 0000cca90000c904ff01000f00000026
block 001ff405: found node 0000e132: 0000cee50000dd32ff0100180000002e
block 001ff429: found node 0000e144: 0000df580000df2b0002000b00000020
block 001ff48d: found node 0000e176: 0000dce70000dce2ff01003100000018
block 001ff493: found node 0000e179: 0000dd470000dce5ff01001f0000002c
block 001ff495: found node 0000e17a: 0000ce0f0000ce11ff01001b0000002a
block 001ff499: found node 0000e17c: 0000d2960000ce10ff01002600000026
block 001ff49f: found node 0000e17f: 0000dd4c0000dceaff01002d00000016
block 001ff4a3: found node 0000e181: 0000dd4e0000dd4cff01002e00000006
block 001ff4a5: found node 0000e182: 0000ce150000ce13ff01002300000026
block 001ff4ad: found node 0000e186: 0000dcbd0000dd4eff0100210000002c
block 001ff4af: found node 0000e187: 0000ce160000d298ff01001c0000002c
block 001ff4b5: found node 0000e18a: 0000d27b0000d27aff01000d00000006
block 001ff4c5: found node 0000e192: 0000d2790000d278ff01000b00000006
block 001ff4d5: found node 0000e19a: 0000d2770000d276ff01000a00000006
block 001ff4db: found node 0000e19d: 0000d2760000d275ff01000a00000006
block 001ff4ef: found node 0000e1a7: 0000d2750000d271ff01000b00000006
block 001ff511: found node 0000e1b8: 0000c9030000cb32ff0100150000000c
block 001ff513: found node 0000e1b9: 0000c9080000dcc3ff01001e00000028
block 001ff559: found node 0000e1dc: 0000d26a0000d269ff01000c00000006
block 001ff595: found node 0000e1fa: 0000d1cb0000d1c9ff01000f00000006
block 001ff5a5: found node 0000e202: 0000d1ca0000d1c7ff01000800000006
block 001ff5ad: found node 0000e206: 0000d1c70000d1c6ff01000f00000006
block 001ff5b5: found node 0000e20a: 0000d1c60000d1c3ff01001800000006
block 001ff5dd: found node 0000e21e: 0000d1bf0000d1bcff01001700000006
block 001ff5f3: found node 0000e229: 0000d1ba0000d1b9ff01000b00000006
block 001ff64f: found node 0000e257: 0000d1410000d140ff01000900000006
block 001ff657: found node 0000e25b: 0000d1400000d13fff01000700000006
block 001ff675: found node 0000e26a: 0000d13b0000d13aff01001200000006
block 001ff689: found node 0000e274: 0000d1380000d136ff01000c00000006
block 001ff6c3: found node 0000e291: 0000d1270000d126ff01000800000006
block 001ff6c9: found node 0000e294: 0000d1260000d125ff01000800000006
block 001ff6e1: found node 0000e2a0: 0000d1210000d11fff01000500000006
block 001ff6fb: found node 0000e2ad: 0000d11a0000d119ff01000b00000006
block 001ff703: found node 0000e2b1: 0000d1190000d118ff01000900000006
block 001ff715: found node 0000e2ba: 0000c14200005d0eff01000800000006
block 001ff71d: found node 0000e2be: 00005d0e00005c47ff01000a00000006
block 001ff725: found node 0000e2c2: 00005c4700005c31ff01000800000006
block 001ff73d: found node 0000e2ce: 00005c2b00005c29ff01000800000006
block 001ff75d: found node 0000e2de: 00003d7900003d78ff01000800000006
block 001ff8e3: found node 0000e3a1: 0000c27d0000d63eff01000f0000004e
block 001ff92f: found node 0000e3c7: 0000c27c00005850ff0100010000005c
block 001ff9f5: found node 0000e42a: 0000d64700005c32ff01004800000006
block 001ffa21: found node 0000e440: 0000d64c0000d64eff01001500000038

