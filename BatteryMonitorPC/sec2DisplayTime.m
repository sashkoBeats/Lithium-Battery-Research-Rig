function disTime = sec2DisplayTime(sec)
    seconds = uint32(sec);
    hours = idivide(seconds,3600);
    seconds = mod(seconds,3600);
    minutes = idivide(seconds,60);
    seconds = mod(seconds, 60);
    disTime = sprintf("%u:%02u:%02u", hours, minutes, seconds);
end