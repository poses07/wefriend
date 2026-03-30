<?php
$sourceFile = 'logo.png';
$outputFile = 'logo_splash.png';

$src = imagecreatefrompng($sourceFile);
$srcWidth = imagesx($src);
$srcHeight = imagesy($src);

// Hedef boyut (orijinalin 2.0 katı kadar boşluklu bir kare)
$targetSize = max($srcWidth, $srcHeight) * 2.0;

$dest = imagecreatetruecolor($targetSize, $targetSize);

// Arka planı transparan yap
imagesavealpha($dest, true);
$transColor = imagecolorallocatealpha($dest, 0, 0, 0, 127);
imagefill($dest, 0, 0, $transColor);

// Orijinal logoyu merkeze yerleştir
$dstX = ($targetSize - $srcWidth) / 2;
$dstY = ($targetSize - $srcHeight) / 2;

imagecopy($dest, $src, $dstX, $dstY, 0, 0, $srcWidth, $srcHeight);

imagepng($dest, $outputFile);
// PHP 8.0 ve sonrasında imagedestroy gerekli değildir (otomatik GC yapar), deprecated uyarısını gidermek için kaldırıldı.

echo "Padded logo created successfully.\n";
