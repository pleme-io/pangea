{
  abstract-synthesizer = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0n8z91za9cljq8js8hjgnflkhxa1vjvb21wywi48h5cxfzqzi6pv";
      type = "gem";
    };
    version = "0.0.9";
  };
  ast = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "04nc8x27hlzlrr5c2gn7mar4vdr0apw5xg22wp6m8dx3wqr04a0y";
      type = "gem";
    };
    version = "2.4.2";
  };
  aws-eventstream = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0fs0shrf2f5dizr8c0lyg0y5j6ixkf6p72i6n5ps6s8xsynv4ra4";
      type = "gem";
    };
    version = "1.3.1";
  };
  aws-partitions = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0af8syr32m1dz1w4cqxgkalghdqq7ilkxfvzmcy4648w45v9izjd";
      type = "gem";
    };
    version = "1.1052.0";
  };
  aws-sdk-core = {
    dependencies = ["aws-eventstream" "aws-partitions" "aws-sigv4" "base64" "jmespath"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0jf64bcgv1iyjhvlax78za4jg6ylgmrwvfvwvf7dxwg1xhr3h36i";
      type = "gem";
    };
    version = "3.219.0";
  };
  aws-sdk-dynamodb = {
    dependencies = ["aws-sdk-core" "aws-sigv4"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0g8048cysd8zysnygb210hk02qxhyn0ifaxsl2d75g5yggdk78rx";
      type = "gem";
    };
    version = "1.137.0";
  };
  aws-sdk-kms = {
    dependencies = ["aws-sdk-core" "aws-sigv4"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1a3mh89kfh6flqxw48wfv9wfwkj2zxazw096mqm56wnnzz1jyads";
      type = "gem";
    };
    version = "1.99.0";
  };
  aws-sdk-s3 = {
    dependencies = ["aws-sdk-core" "aws-sdk-kms" "aws-sigv4"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "03a55dbihv6xvgfwhx0f35rwc7q3rr0555vfpxlwpdjw75wkbz6h";
      type = "gem";
    };
    version = "1.182.0";
  };
  aws-sigv4 = {
    dependencies = ["aws-eventstream"];
    groups = ["default" "production"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1nx1il781qg58nwjkkdn9fw741cjjnixfsh389234qm8j5lpka2h";
      type = "gem";
    };
    version = "1.11.0";
  };
  base64 = {
    groups = ["default" "production"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "01qml0yilb9basf7is2614skjp8384h2pycfx86cr8023arfj98g";
      type = "gem";
    };
    version = "0.2.0";
  };
  bigdecimal = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1k6qzammv9r6b2cw3siasaik18i6wjc5m0gw5nfdc6jj64h79z1g";
      type = "gem";
    };
    version = "3.1.9";
  };
  citrus = {
    groups = ["default" "production"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0l7nhk3gkm1hdchkzzhg2f70m47pc0afxfpl6mkiibc9qcpl3hjf";
      type = "gem";
    };
    version = "3.0.2";
  };
  date = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0kz6mc4b9m49iaans6cbx031j9y7ldghpi5fzsdh0n3ixwa8w9mz";
      type = "gem";
    };
    version = "3.4.1";
  };
  debug = {
    dependencies = ["irb" "reline"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1977s95s9ns6mpbhg68pg6ggnpxxf8wly4244ihrx5vm92kqrqhi";
      type = "gem";
    };
    version = "1.10.0";
  };
  debug_inspector = {
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "18k8x9viqlkh7dbmjzh8crbjy8w480arpa766cw1dnn3xcpa1pwv";
      type = "gem";
    };
    version = "1.2.0";
  };
  diff-lcs = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0bnss89lcm3b1k3xcjd35grxqz5q040d12imd73qybwnfarggrx1";
      type = "gem";
    };
    version = "1.6.0";
  };
  io-console = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "18pgvl7lfjpichdfh1g50rpz0zpaqrpr52ybn9liv1v9pjn9ysnd";
      type = "gem";
    };
    version = "0.8.0";
  };
  irb = {
    dependencies = ["pp" "rdoc" "reline"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1478m97wiy6nwg6lnl0szy39p46acsvrhax552vsh1s2mi2sgg6r";
      type = "gem";
    };
    version = "1.15.1";
  };
  jmespath = {
    groups = ["default" "production"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1cdw9vw2qly7q7r41s7phnac264rbsdqgj4l0h4nqgbjb157g393";
      type = "gem";
    };
    version = "1.6.2";
  };
  json = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1p4l5ycdxfsr8b51gnvlvhq6s21vmx9z4x617003zbqv3bcqmj6x";
      type = "gem";
    };
    version = "2.10.1";
  };
  language_server-protocol = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0scnz2fvdczdgadvjn0j9d49118aqm3hj66qh8sd2kv6g1j65164";
      type = "gem";
    };
    version = "3.17.0.4";
  };
  lint_roller = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "11yc0d84hsnlvx8cpk4cbj6a4dz9pk0r1k29p0n1fz9acddq831c";
      type = "gem";
    };
    version = "1.1.0";
  };
  logger = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "05s008w9vy7is3njblmavrbdzyrwwc1fsziffdr58w9pwqj8sqfx";
      type = "gem";
    };
    version = "1.6.6";
  };
  pangea = {
    dependencies = ["abstract-synthesizer" "aws-sdk-dynamodb" "aws-sdk-s3" "bigdecimal" "rexml" "terraform-synthesizer" "toml-rb" "tty-box" "tty-color" "tty-option" "tty-progressbar" "tty-table"];
    groups = ["default"];
    platforms = [];
    source = {
      path = ./.;
      type = "path";
    };
    version = "0.0.46";
  };
  parallel = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1vy7sjs2pgz4i96v5yk9b7aafbffnvq7nn419fgvw55qlavsnsyq";
      type = "gem";
    };
    version = "1.26.3";
  };
  parser = {
    dependencies = ["ast" "racc"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "18dcwrcnddvi8gl3hmbsb2cj1l7afxk2lh3jmhj90l95h1hn3gkx";
      type = "gem";
    };
    version = "3.3.7.1";
  };
  pastel = {
    dependencies = ["tty-color"];
    groups = ["default" "production"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0xash2gj08dfjvq4hy6l1z22s5v30fhizwgs10d6nviggpxsj7a8";
      type = "gem";
    };
    version = "0.8.0";
  };
  pp = {
    dependencies = ["prettyprint"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1zxnfxjni0r9l2x42fyq0sqpnaf5nakjbap8irgik4kg1h9c6zll";
      type = "gem";
    };
    version = "0.6.2";
  };
  prettyprint = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "14zicq3plqi217w6xahv7b8f7aj5kpxv1j1w98344ix9h5ay3j9b";
      type = "gem";
    };
    version = "0.2.0";
  };
  prism = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0fi7hvrm2wzbhm21d3w87z5nrqx6z0gwhilvdizcpc9ik21205mi";
      type = "gem";
    };
    version = "1.3.0";
  };
  psych = {
    dependencies = ["date" "stringio"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1vjrx3yd596zzi42dcaq5xw7hil1921r769dlbz08iniaawlp9c4";
      type = "gem";
    };
    version = "5.2.3";
  };
  racc = {
    groups = ["default" "development" "production"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0byn0c9nkahsl93y9ln5bysq4j31q8xkf2ws42swighxd4lnjzsa";
      type = "gem";
    };
    version = "1.8.1";
  };
  rainbow = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0smwg4mii0fm38pyb5fddbmrdpifwv22zv3d3px2xx497am93503";
      type = "gem";
    };
    version = "3.1.1";
  };
  rake = {
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "17850wcwkgi30p7yqh60960ypn7yibacjjha0av78zaxwvd3ijs6";
      type = "gem";
    };
    version = "13.2.1";
  };
  rbs = {
    dependencies = ["logger"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "07cwjkx7b3ssy8ccqq1s34sc5snwvgxan2ikmp9y2rz2a9wy6v1b";
      type = "gem";
    };
    version = "3.8.1";
  };
  rdoc = {
    dependencies = ["psych"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1q2nkyk6r3m15a2an7lwm4ilkcxzdh3j93s4ib8sbzqb0xp70vvx";
      type = "gem";
    };
    version = "6.12.0";
  };
  regexp_parser = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0qccah61pjvzyyg6mrp27w27dlv6vxlbznzipxjcswl7x3fhsvyb";
      type = "gem";
    };
    version = "2.10.0";
  };
  reline = {
    dependencies = ["io-console"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1lirwlw59apc8m1wjk85y2xidiv0fkxjn6f7p84yqmmyvish6qjp";
      type = "gem";
    };
    version = "0.6.0";
  };
  rexml = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1jmbf6lf7pcyacpb939xjjpn1f84c3nw83dy3p1lwjx0l2ljfif7";
      type = "gem";
    };
    version = "3.4.1";
  };
  rspec = {
    dependencies = ["rspec-core" "rspec-expectations" "rspec-mocks"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "14xrp8vq6i9zx37vh0yp4h9m0anx9paw200l1r5ad9fmq559346l";
      type = "gem";
    };
    version = "3.13.0";
  };
  rspec-core = {
    dependencies = ["rspec-support"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1r6zbis0hhbik1ck8kh58qb37d1qwij1x1d2fy4jxkzryh3na4r5";
      type = "gem";
    };
    version = "3.13.3";
  };
  rspec-expectations = {
    dependencies = ["diff-lcs" "rspec-support"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0n3cyrhsa75x5wwvskrrqk56jbjgdi2q1zx0irllf0chkgsmlsqf";
      type = "gem";
    };
    version = "3.13.3";
  };
  rspec-mocks = {
    dependencies = ["diff-lcs" "rspec-support"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1vxxkb2sf2b36d8ca2nq84kjf85fz4x7wqcvb8r6a5hfxxfk69r3";
      type = "gem";
    };
    version = "3.13.2";
  };
  rspec-support = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1v6v6xvxcpkrrsrv7v1xgf7sl0d71vcfz1cnrjflpf6r7x3a58yf";
      type = "gem";
    };
    version = "3.13.2";
  };
  rubocop = {
    dependencies = ["json" "language_server-protocol" "lint_roller" "parallel" "parser" "rainbow" "regexp_parser" "rubocop-ast" "ruby-progressbar" "unicode-display_width"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0sz9782vyhm7kn1p2jfvr4cpfdcnwr3qhkacpy10irpyi4ns6n82";
      type = "gem";
    };
    version = "1.72.2";
  };
  rubocop-ast = {
    dependencies = ["parser"];
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1bi6pgnii77763dzwhafcp8lrmnh4n1bqbdimhc9lfj4zs96gpsg";
      type = "gem";
    };
    version = "1.38.0";
  };
  rubocop-rake = {
    dependencies = ["lint_roller" "rubocop"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0kdfrckz1v32dy7c7bdiksjysx9l9zsda9kc6zvrsghch6vg55rp";
      type = "gem";
    };
    version = "0.7.1";
  };
  rubocop-rspec = {
    dependencies = ["lint_roller" "rubocop"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0k1hsppf3p72q9phm2084ad94ldhvf5vnp57xsl4p25gw4pr833i";
      type = "gem";
    };
    version = "3.5.0";
  };
  ruby-lsp = {
    dependencies = ["language_server-protocol" "prism" "rbs" "sorbet-runtime"];
    groups = ["development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1hx0hb0j0jpzizc76sjrmvgvwifr7507xap66wzg6mj3mqc0y46r";
      type = "gem";
    };
    version = "0.23.11";
  };
  ruby-progressbar = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0cwvyb7j47m7wihpfaq7rc47zwwx9k4v7iqd9s1xch5nm53rrz40";
      type = "gem";
    };
    version = "1.13.0";
  };
  sorbet-runtime = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0kl3m025s956m4y362l6wfvgjzqdl9chc7ayh345471wfrzzpc0i";
      type = "gem";
    };
    version = "0.5.11839";
  };
  stringio = {
    groups = ["default" "development"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0w0xb48347vclpagqs9qbmcgrq9npxnr4v8zq8bhhqc839pqzmkx";
      type = "gem";
    };
    version = "3.1.4";
  };
  strings = {
    dependencies = ["strings-ansi" "unicode-display_width" "unicode_utils"];
    groups = ["default" "production"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1yynb0qhhhplmpzavfrrlwdnd1rh7rkwzcs4xf0mpy2wr6rr6clk";
      type = "gem";
    };
    version = "0.2.1";
  };
  strings-ansi = {
    groups = ["default" "production"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "120wa6yjc63b84lprglc52f40hx3fx920n4dmv14rad41rv2s9lh";
      type = "gem";
    };
    version = "0.2.0";
  };
  terraform-synthesizer = {
    dependencies = ["abstract-synthesizer"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1jzv4arl0gp9g7k5b3svwmcxmbyjbxrymw389mz1j9hm60ynb4sm";
      type = "gem";
    };
    version = "0.0.26";
  };
  toml-rb = {
    dependencies = ["citrus" "racc"];
    groups = ["production"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1ch068k06ag358wlmid3psqlniq9y51hfazp0w9bbrw5vpf699x3";
      type = "gem";
    };
    version = "3.0.1";
  };
  tty-box = {
    dependencies = ["pastel" "strings" "tty-cursor"];
    groups = ["production"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "12yzhl3s165fl8pkfln6mi6mfy3vg7p63r3dvcgqfhyzq6h57x0p";
      type = "gem";
    };
    version = "0.7.0";
  };
  tty-color = {
    groups = ["production"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0aik4kmhwwrmkysha7qibi2nyzb4c8kp42bd5vxnf8sf7b53g73g";
      type = "gem";
    };
    version = "0.6.0";
  };
  tty-cursor = {
    groups = ["default" "production"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0j5zw041jgkmn605ya1zc151bxgxl6v192v2i26qhxx7ws2l2lvr";
      type = "gem";
    };
    version = "0.7.1";
  };
  tty-option = {
    groups = ["production"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "019ir4bcr8fag7dmq7ph6ilpvwjbv4qalip0bz7dlddbd6fk4vjs";
      type = "gem";
    };
    version = "0.3.0";
  };
  tty-progressbar = {
    dependencies = ["strings-ansi" "tty-cursor" "tty-screen" "unicode-display_width"];
    groups = ["production"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1xm5sk1sqp7v16akqpxza672qza6dbml68ah1lcajx2ywmh45fvc";
      type = "gem";
    };
    version = "0.18.3";
  };
  tty-screen = {
    groups = ["default" "production"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0l4vh6g333jxm9lakilkva2gn17j6gb052626r1pdbmy2lhnb460";
      type = "gem";
    };
    version = "0.8.2";
  };
  tty-table = {
    dependencies = ["pastel" "strings" "tty-screen"];
    groups = ["production"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0fcrbfb0hjd9vkkazkksri93dv9wgs2hp6p1xwb1lp43a13pmhpx";
      type = "gem";
    };
    version = "0.12.0";
  };
  unicode-display_width = {
    groups = ["default" "development" "production"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0nkz7fadlrdbkf37m0x7sw8bnz8r355q3vwcfb9f9md6pds9h9qj";
      type = "gem";
    };
    version = "2.6.0";
  };
  unicode_utils = {
    groups = ["default" "production"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0h1a5yvrxzlf0lxxa1ya31jcizslf774arnsd89vgdhk4g7x08mr";
      type = "gem";
    };
    version = "1.4.0";
  };
}
