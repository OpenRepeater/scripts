function dummysnd_setup () {
modprobe snd-dummy

cat >> /etc/modules << DELIM
snd-dummy
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
