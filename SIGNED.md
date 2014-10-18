##### Signed by https://keybase.io/rdprabhu
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG v2

iQEcBAABAgAGBQJUQnq6AAoJEKYW3KHXK+l3pHQH/R1Qxa/UqhmeOM0Anq94KRXh
ko7xKMVCQRFWAeHtKdEYfef1nUqvoaMyjdKwPTM4SboMUtSVdUjKueoDCnQlbzZn
634eNl+SV+aXW7Yzdzr57Yi/tIpaSpeZRmxXUDJEEjx3MUcJfJMMo8xgKmqiyoG5
Ve8qzC8HUiwBXLwBC3LJk4PmNy0ZVE2abjlR9ymdrj1Xo5kwe+wRyXNXISx02ltV
ON+H99sx7pNBlKDIOOPPA+v9Jg31q3haeaDVvLo3eJgtHiL0RH6Rx0MAAXsz0gkZ
CdFoKZIkNTAE+Oh9r4jA4eYwsRGSMzruX3bBc9qaYtB3BAJC63MP8JCdfElIlMY=
=p8DJ
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size   exec  file                     contents                                                        
             ./                                                                                       
18027          LICENSE                a45d0bb572ed792ed34627a72621834b3ba92aab6e2cc4e04301dee7a728d753
177            README.md              a0b4893eddd0de87a452b56c66c4a2fb9e8eb93d8b171190a2883a74988b6cbf
               dnsmasq/                                                                               
353              Dockerfile           107021af99559f6a09ad58e96a5b615b3aac858743950a56ec5d5f9062cdcf8c
               docker-pkgs/                                                                           
                 pxc-experimental/                                                                    
324                Dockerfile1        f6ea27dc59b2544fe1001cb4bddb45746a0897c7748bec38f603d9251c01ce39
316                Dockerfile2        86c22036c2b0ce07adcdce1573f675e86053b0dc84df38287328c4cbdc8cba3a
316                Dockerfile3        d9c0f3bd98b14666e1163f1416d1e8e688e876d74cd1d3e69181fb2d46d806b7
                 pxc-release/                                                                         
                   pxc1/                                                                              
458                  Dockerfile       0a2ec4b3389c18eaeb61638155c131099aa73b83decae27251bc187850021a19
445                  node1.cnf        5f4dca14105472a844b73ce28865ebc1f243bef1692ff93f10c3fead980bf432
                   pxc2/                                                                              
449                  Dockerfile       cac84600c8bf5568c17e481d53b0c0d93c6f4876e0d45106d4dc8f552819085a
476                  node2.cnf        5573bc228a634031ce0132d86e112f95000679cb8db124068d035f7f7fe0234b
                   pxc3/                                                                              
449                  Dockerfile       bb284c11d57b74ba97014deaf79df8a6a36915cacc44843dc352176a99eea915
482                  node3.cnf        becc76ba1d19a0255068f1a5bbe67b8601abb403311eaf37691b5cceb775dd10
                 pxc-testing/                                                                         
297                Dockerfile1        0fcd0abbb75c4584b3157f66120437a40ddf7d0235478484e9f63882a934b04d
289                Dockerfile2        441273e10a4885eb36b5df10799378089778214772c06d4f1c1a03648ffe1ac1
289                Dockerfile3        d9edec10238684c342eb413c678dbb348ea27374ab0ea32688874c9c05e93065
               docker-tarball/                                                                        
827              Dockerfile           94defccaa62849365a7dc92eb78f63ac6e20e5610fde99869146ccc211e87216
433              node.cnf             063962bad252523fb9947ca3fd0615c23143e8ba59735f7fdd2eadce7abae344
               partition-test/                                                                        
1006             backtrace.gdb        5291f00cf8387c758374c97d2fea49b976807f988531675e6b3b6711a6a4c20a
19306  x         galera-partition.sh  73458141f6719826b92510ae66e1bf3a380faa86cdc664708611780c6bd74f46
```

#### Ignore

```
/SIGNED.md
```

#### Presets

```
git      # ignore .git and anything as described by .gitignore files
dropbox  # ignore .dropbox-cache and other Dropbox-related files    
kb       # ignore anything as described by .kbignore files          
```

<!-- summarize version = 0.0.9 -->

### End signed statement

<hr>

#### Notes

With keybase you can sign any directory's contents, whether it's a git repo,
source code distribution, or a personal documents folder. It aims to replace the drudgery of:

  1. comparing a zipped file to a detached statement
  2. downloading a public key
  3. confirming it is in fact the author's by reviewing public statements they've made, using it

All in one simple command:

```bash
keybase dir verify
```

There are lots of options, including assertions for automating your checks.

For more info, check out https://keybase.io/docs/command_line/code_signing