function dummysnd_setup () {
modprobe snd-dummy fake_buffer=0

cat >> /etc/modules << DELIM
snd-dummy fake_buffer=0
DELIM
    
touch /etc/asound.conf
 
cat >> /etc/asound.conf << DELIM
pcm.card0 {
    type hw
    card 0
}
ctl.card0 {
    type hw
    card 0
}
DELIM
   
}
