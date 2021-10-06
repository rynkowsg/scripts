# gpg

## Docs

- https://www.gnupg.org/documentation/manuals/gnupg.pdf
- https://wiki.archlinux.org/title/GnuPG
- https://wiki.archlinux.org/title/Paperkey

## Use cases

### config
```shell
% gpg --list-config --with-colons
cfg:version:2.3.1
cfg:pubkey:1;16;17;18;19;22
cfg:pubkeyname:RSA;ELG;DSA;ECDH;ECDSA;EDDSA
cfg:cipher:1;2;3;4;7;8;9;10;11;12;13
cfg:ciphername:IDEA;3DES;CAST5;BLOWFISH;AES;AES192;AES256;TWOFISH;CAMELLIA128;CAMELLIA192;CAMELLIA256
cfg:digest:2;3;8;9;10;11
cfg:digestname:SHA1;RIPEMD160;SHA256;SHA384;SHA512;SHA224
cfg:compress:0;1;2;3
cfg:compressname:Uncompressed;ZIP;ZLIB;BZIP2
cfg:curve:cv25519;ed25519;cv448;ed448;nistp256;nistp384;nistp521;brainpoolP256r1;brainpoolP384r1;brainpoolP512r1;secp256k1
```

### gen a master key
```shell
% gpg --batch --status-fd 1 --no-tty --passphrase '' --quick-generate-key 'Grzegorz Rynkowski <pgp@rynkowski.pl>' rsa4096 cert 2030-01-01
gpg: key 13B73AC8E416556B marked as ultimately trusted
[GNUPG:] KEY_CONSIDERED 2334B4E1CE62E2A2759E5DB213B73AC8E416556B 0
gpg: revocation certificate stored as '/Users/greg/.gnupg/openpgp-revocs.d/2334B4E1CE62E2A2759E5DB213B73AC8E416556B.rev'
[GNUPG:] KEY_CREATED P 2334B4E1CE62E2A2759E5DB213B73AC8E416556B

% gpg --list-keys
/Users/greg/.gnupg/pubring.kbx
------------------------------
pub   rsa4096 2021-06-27 [C] [expires: 2030-01-01]
      2334B4E1CE62E2A2759E5DB213B73AC8E416556B
uid           [ultimate] Grzegorz Rynkowski <pgp@rynkowski.pl>

% gpg --list-secret-keys
/Users/greg/.gnupg/pubring.kbx
------------------------------
sec   rsa4096 2021-06-27 [C] [expires: 2030-01-01]
      2334B4E1CE62E2A2759E5DB213B73AC8E416556B
uid           [ultimate] Grzegorz Rynkowski <pgp@rynkowski.pl>
```

### export public key
```shell
gpg --armor --export 2334B4E1CE62E2A2759E5DB213B73AC8E416556B > public-master-key.asc
# or
gpg --armor --output public-master-key.asc --export 2334B4E1CE62E2A2759E5DB213B73AC8E416556B
```

### export secret key
```shell
# export to file (with armor)
gpg --armor --output secret-master-key.asc --export-secret-key 2334B4E1CE62E2A2759E5DB213B73AC8E416556B
# export to file (with paper)
gpg --export-secret-key 2334B4E1CE62E2A2759E5DB213B73AC8E416556B | paperkey -o secret-master-key.paper.asc
# export and print
gpg --export-secret-key 2334B4E1CE62E2A2759E5DB213B73AC8E416556B | paperkey | lpr
# export to QR code
gpg --export-secret-key 2334B4E1CE62E2A2759E5DB213B73AC8E416556B | paperkey --output-type raw | qrencode --8bit --output secret-key.qr.png

gpg --export-secret-key 2334B4E1CE62E2A2759E5DB213B73AC8E416556B | paperkey --output-type raw | qrencode --16bit | lpr
```

### import public key
```shell
$ curl --silent https://sneak.berlin/.well-known/pgpkey.txt | gpg --import
gpg: key 052443F4DF2A55C2: 58 signatures not checked due to missing keys
gpg: key 052443F4DF2A55C2: public key "Jeffrey Paul <sneak@sneak.berlin>" imported
gpg: Total number processed: 1
gpg:               imported: 1
gpg: no ultimately trusted keys found
```

### import secret key
```shell
% cat secret-master-key.asc | gpg --import
# or
% gpg --import secret-master-key.asc
```

### restore secret key from paper
```shell
# dearmor public key
% gpg --output public-master-key.gpg --dearmor public-master-key.asc
# restore secret key from paper key
% paperkey --pubring public-master-key.gpg --secrets secret-master-key.paper.asc --output secret-master-key-from-paper.gpg
# compare
% md5sum secret-master-key-from-paper.asc secret-master-key.gpg
e8ec093f7daabb312d4865c984db31eb  secret-master-key-from-paper.asc
e8ec093f7daabb312d4865c984db31eb  secret-master-key.gpg
```

### preview key without importing it

```shell
% wget --no-verbose https://sneak.berlin/.well-known/pgpkey.txt
2021-06-27 16:39:44 URL:https://sneak.berlin/.well-known/pgpkey.txt [49159] -> "pgpkey.txt" [1]

% gpg pgpkey.txt
gpg: WARNING: no command supplied.  Trying to guess what you mean ...
pub   rsa4096 2010-10-21 [SC]
5539AD00DE4C42F3AFE11575052443F4DF2A55C2
uid           Jeffrey Paul <jp@eeqj.com>
uid           Jeffrey Paul <admin@datavibe.net>
uid           [jpeg image of size 8096]
uid           Jeffrey Paul <sneak@acidhou.se>
uid           Jeffrey Paul <sneak@sneak.berlin>
sub   rsa4096 2010-10-21 [E]
sub   rsa4096 2015-06-21 [A]
```
or
```shell
% curl -sf https://sneak.berlin/.well-known/pgpkey.txt | gpg
# ...
```

###  remove key
```shell
% gpg --batch --delete-keys 5539AD00DE4C42F3AFE11575052443F4DF2A55C2
# if you use --batch and fingerprint, there is no need to confirm
% gpg --list-keys
# no keys
```

### delete secret key
```shell
% gpg --batch --yes --delete-secret-keys 2334B4E1CE62E2A2759E5DB213B73AC8E416556B
% gpg --batch --yes --delete-keys 2334B4E1CE62E2A2759E5DB213B73AC8E416556B
% gpg --list-secret-keys
# no secret keys
% gpg --list-keys
gpg: checking the trustdb
gpg: no ultimately trusted keys found
# no keys
```

### generate subkeys
```shell
% gpg --batch --status-fd 1 --pinentry-mode loopback --passphrase '' --quick-add-key 2334B4E1CE62E2A2759E5DB213B73AC8E416556B rsa4096 encrypt 1y
[GNUPG:] KEY_CONSIDERED 2334B4E1CE62E2A2759E5DB213B73AC8E416556B 0
[GNUPG:] KEY_CREATED S 3CA1A138E3C94A848B6E31817C7207D8740A7CFB

% gpg --batch --status-fd 1 --pinentry-mode loopback --passphrase '' --quick-add-key 2334B4E1CE62E2A2759E5DB213B73AC8E416556B rsa4096 sign 1y
[GNUPG:] KEY_CONSIDERED 2334B4E1CE62E2A2759E5DB213B73AC8E416556B 0
[GNUPG:] KEY_CREATED S A78D82B66F74E64D665810E8577F22F36E0766A5

% gpg --batch --status-fd 1 --pinentry-mode loopback --passphrase '' --quick-add-key 2334B4E1CE62E2A2759E5DB213B73AC8E416556B rsa4096 auth 1y
[GNUPG:] KEY_CONSIDERED 2334B4E1CE62E2A2759E5DB213B73AC8E416556B 0
[GNUPG:] KEY_CREATED S 32DA2BED4271B65822ECD89813752D7ADE8BB649

% gpg --list-keys
/Users/greg/.gnupg/pubring.kbx
------------------------------
pub   rsa4096 2021-06-27 [C] [expires: 2030-01-01]
      2334B4E1CE62E2A2759E5DB213B73AC8E416556B
uid           [ultimate] Grzegorz Rynkowski <pgp@rynkowski.pl>
sub   rsa4096 2021-06-27 [E] [expires: 2022-06-27]
sub   rsa4096 2021-06-27 [S] [expires: 2022-06-27]
sub   rsa4096 2021-06-27 [A] [expires: 2022-06-27]
```

### preview photo attached to the key
```shell
## WHEN KEY IMPORTED
% curl -sf https://sneak.berlin/.well-known/pgpkey.txt | gpg --import
# show photo id of 0x5539AD00DE4C42F3AFE11575052443F4DF2A55C2
% gpg --list-options show-photos --list-key 5539AD00DE4C42F3AFE11575052443F4DF2A55C2
# export photo id to 0x5539AD00DE4C42F3AFE11575052443F4DF2A55C2.jpg
% gpg --list-options show-photos --photo-viewer "cat > ./0x%f.%t" --list-key 5539AD00DE4C42F3AFE11575052443F4DF2A55C2
## OR WITHOUT IMPORTING
% curl -sf https://sneak.berlin/.well-known/pgpkey.txt | gpg --list-options show-photos --list-key 5539AD00DE4C42F3AFE11575052443F4DF2A55C2
% curl -sf https://sneak.berlin/.well-known/pgpkey.txt | gpg --list-options show-photos --photo-viewer "cat > ./0x%f.%t" --list-key 5539AD00DE4C42F3AFE11575052443F4DF2A55C2
## MORE EXAMPLES
% curl -sf https://sneak.berlin/.well-known/pgpkey.txt | gpg --list-options show-photos --list-key 5539AD00DE4C42F3AFE11575052443F4DF2A55C2
% curl -sf https://www.preining.info/rsa.asc | gpg --list-options show-photos --list-key F7D8A92826E316A19FA0ACF06CACA448860CDC13
% curl -sf https://gpg.pashinskikh.de/pashinskikh.asc | gpg --list-options show-photos --list-key 85E38F69046B44C1EC9FB07B76D78F0500D026C4
```

## Links

### adding a photo id

- https://www.gnupg.org/documentation/manuals/gnupg/OpenPGP-Key-Management.html
- https://pashynskykh.com/posts/gpg/
- https://wordpress.matbra.com/en/2012/04/12/adicionar-foto-a-chave-pgpgpg-using-gnupg/
- https://manpages.ubuntu.com/manpages//precise/en/man1/gpg.1.html
- https://gist.github.com/Integralist/f7e17034800b65b51eb7e9807720025a

### paper key

- https://wiki.archlinux.org/title/Paperkey

- idea how to split paper key into separate files:
  http://blog.cyphermox.net/2018/03/backing-up-gpg-keys.html

  backup:

      cat printme.txt | split -b 1500 - part-
      rm printme.txt
      for part in part-*; do
      dmtxwrite -e 8 ${part} > ${part}.png
      done

  restore:

      for file in *.png; do dmtxread $file >> printme.txt; done
