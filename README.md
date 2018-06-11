# cleos_voter
cleos_voter for multi account

### About
cleos_voter has been created by users with multiple EOS accounts to easily make Producer votes.

### Voting
move the voter script to EOS_SOURCE_DIRECTORY/build/programs/at the bottom
Set the Execute permission to run the script.

```
cp -a voter.sh ~/eos_src/build/programs/voter.sh
chmod + x voter.sh
cd ~/eos_src/build/programs/
./voter.sh _KEYFILE _PRODUCER
```

Please refer to the sample file attached with the configuration of the key file.
