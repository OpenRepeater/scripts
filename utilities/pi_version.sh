#!/bin/bash

CPU_REV=$(grep Revision /proc/cpuinfo | cut -f 2 -d: | tr -d '[:space:]')


case $CPU_REV in

	900021)
		MODEL="A+"
		REV="1.1"
		RAM="512MB"
		MFG="Sony UK"
		DATE="Q3 2016"
		;;

	900032)
		MODEL="B+"
		REV="1.2"
		RAM="512MB"
		MFG="Sony UK"
		DATE="Q2 2016"
		;;

	900092)
		MODEL="Zero"
		REV="1.2"
		RAM="512MB"
		MFG="Sony UK"
		DATE="Q4 2015"
		;;

	900093)
		MODEL="Zero"
		REV="1.3"
		RAM="512MB"
		MFG="Sony UK"
		DATE="Q2 2016"
		;;

	9000c1)
		MODEL="Zero W"
		REV="1.1"
		RAM="512MB"
		MFG="Sony UK"
		DATE="Q1 2017"
		;;

	9020e0)
		MODEL="3A+"
		REV="1.0"
		RAM="512MB"
		MFG="Sony UK"
		DATE="Q4 2018"
		;;

	920092)
		MODEL="Zero"
		REV="1.2"
		RAM="512MB"
		MFG="Embest"
		;;

	920093)
		MODEL="Zero"
		REV="1.3"
		RAM="512MB"
		MFG="Embest"
		DATE="Q4 2016"
		;;

	900061)
		MODEL="CM"
		REV="1.1"
		RAM="512MB"
		MFG="Sony UK"
		;;

	a01040)
		MODEL="2B"
		REV="1.0"
		RAM="1GB"
		MFG="Sony UK"
		DATE="?"
		;;

	a01041)
		MODEL="2B"
		REV="1.1"
		RAM="1GB"
		MFG="Sony UK"
		DATE="Q1 2015"
		;;

	a02082)
		MODEL="3B"
		REV="1.2"
		RAM="1GB"
		MFG="Sony UK"
		DATE="Q1 2016"
		;;

	a020a0)
		MODEL="CM3"
		REV="1.0"
		RAM="1GB"
		MFG="Sony UK"
		DATE="Q1 2017"
		;;

	a020d3)
		MODEL="3B+"
		REV="1.3"
		RAM="1GB"
		MFG="Sony UK"
		DATE="Q1 2018"
		;;

	a02042)
		MODEL="2B (with BCM2837)"
		REV="1.2"
		RAM="1GB"
		MFG="Sony UK"
		DATE="2016"
		;;

	a21041)
		MODEL="2B"
		REV="1.1"
		RAM="1GB"
		MFG="Embest"
		DATE="Q1 2015"
		;;

	a22042)
		MODEL="2B (with BCM2837)"
		REV="1.2"
		RAM="1GB"
		MFG="Embest"
		DATE="Q2 2016"
		;;

	a22082)
		MODEL="3B"
		REV="1.2"
		RAM="1GB"
		MFG="Embest"
		DATE="Q1 2016"
		;;

	a220a0)
		MODEL="CM3"
		REV="1.0"
		RAM="1GB"
		MFG="Embest"
		;;

	a32082)
		MODEL="3B"
		REV="1.2"
		RAM="1GB"
		MFG="Sony Japan"
		DATE="Q4 2016"
		;;

	a52082)
		MODEL="3B"
		REV="1.2"
		RAM="1GB"
		MFG="Stadium"
		;;

	a22083)
		MODEL="3B"
		REV="1.3"
		RAM="1GB"
		MFG="Embest"
		;;

	a02100)
		MODEL="CM3+"
		REV="1.0"
		RAM="1GB"
		MFG="Sony UK"
		;;

	a03111)
		MODEL="4B"
		REV="1.1"
		RAM="1GB"
		MFG="Sony UK"
		DATE="Q2 2019"
		;;

	b03111)
		MODEL="4B"
		REV="1.1"
		RAM="2GB"
		MFG="Sony UK"
		DATE="Q2 2019"
		;;

	b03112)
		MODEL="4B"
		REV="1.2"
		RAM="2GB"
		MFG="Sony UK"
		DATE="2019"
		;;

	b03114)
		MODEL="4B"
		REV="1.4"
		RAM="2GB"
		MFG="Sony UK"
		DATE="2019"
		;;

	c03111)
		MODEL="4B"
		REV="1.1"
		RAM="4GB"
		MFG="Sony UK"
		DATE="Q2 2019"
		;;

	c03112)
		MODEL="4B"
		REV="1.2"
		RAM="4GB"
		MFG="Sony UK"
		DATE="2019"
		;;

	c03114)
		MODEL="4B"
		REV="1.4"
		RAM="8GB"
		MFG="Sony UK"
		DATE="2019"
		;;

	d03114)
		MODEL="4B"
		REV="1.4"
		RAM="8GB"
		MFG="Sony UK"
		DATE="2019"
		;;

	c03130)
		MODEL="Pi 400"
		REV="1.0"
		RAM="4GB"
		MFG="Sony UK"
		DATE="Q4 2020"
		;;

	*)
		MODEL="Unknown"
		;;
esac



echo "---------------------------------------"
echo " About this Raspberry Pi"
echo "---------------------------------------"
if [ "$MODEL" == "Unknown" ]; then
    echo "Unknown Model"
else
	echo "Model: $MODEL"
	echo "Revision: $REV"
	echo "Memory: $RAM"
	echo "Manufacture: $MFG"
	if [ -n "$DATE" ]; then echo "Released: $DATE"; fi
fi