# Mute Speaker
This is a MacOS utility that detects when a particular person is speaking and fast forwards any media that is currently being played until that person's voice is no longer detected.

This is useful when you might be interested in listening to a guest from a long podcast, but really are not interested in the host's commentary or vice versa.

It requires compilation from cli using swift compiler. You can then add the generated binary to your login items. See the yaml file for options including speakers to mute.


```bash
swiftc media.swift
./media
```


### Feedback
Please send any feedback or suggestions to [@soheil](https://twitter.com/soheil).
