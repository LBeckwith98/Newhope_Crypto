# Newhope_Crypto
This repository contains an implementation of the Newhope cryptosystem's encryption and decryption operation in Verilog. It also provides three testbench files, one for the encrypter and one for the decrypter both using test vectors generated from the reference implementation provided by the [authors](https://newhopecrypto.org/resources.shtml). The third test bench tests that the decrypter successfuly decrypts a ciphertext generated by the encrypter using the public key and secret key generated from the reference implementation.

## Module Descriptions:

__Encrypter:__

The encrypter takes the following inputs:
  * 896-byte encoded polynomial (public key)
  * 32-byte public seed value (public key)
  * 32-byte message
  * 32-byte random coin
  
These values are used to encrypt the 32-byte input message into a 1088-byte ciphertext. Due to the way the internal modules access the different input values, there are two internal blocks of RAM that the inputs are loaded into. The public seed, coin, and message are loaded into the internal memory 32-bits at a time using *input1_addra_enc*, *input1_dia_enc*, and *input1_wea_enc*. The encoded polynomial is loaded in 8-bits at a time using *input2_addra_enc*, *input2_dia_enc*, and *input2_wea_enc*. It is currently assumed that the reset signal will be asserted between runs. Once the start signal is asserted for one clock cycle the encrypter will run and will assert the done signal for one clock cycle upon completion. At that point the ciphertext can be read out 8-bits at a time using the **output_addr* and **output_do* signals.

__Decrypter:__

The decrypter takes the following inputs:
  * 1088-byte ciphertext
  * 896-byte encoded polynomial (secret key)

These values are used to decrypt the ciphertext to the 32-byte plaintext which can be then be expanded using SHAKE256 as needed to generate a shared secret value. The values are loaded into a single internal RAM using the **input_dia**, **input_addra** and **input_wea** signals with the ciphertext being placed in the lower 1088-bytes and the secret key being placed in the upper 896-bytes. It is currently assumed that the reset signal will be asserted between runs. Once the start signal is asserted for one clock cycle the decrypter will run and will assert the done signal for one clock cycle upon completion. At that point the plaintext can be read out 32-bits at a time using the **output_addr** and **output_do** signals.

_Usage_
To run, you must change the base filepath for the testvectors and the BRAM initialization vectors. The changes that need to be changed are at the following locations:
  * tb_decrypter.v:63
  * tb_encrypter.v:70
  * tb_newhope.v:111
  * tb_newhope.v:112
  * encrypter.v:185
  * encrypter.v:187
  * decrypter.v:201

