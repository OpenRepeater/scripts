function dummysnd_setup () {
modprobe snd-dummy fake_buffer=0

cat >> /etc/modules << DELIM
snd-dummy fake_buffer=0
DELIM
    
}
