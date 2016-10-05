<?php

/* Captcha solving client utility for facebook rss-bridge
 *
 * Initially written for Facebook captcha cleaning
 * Might be re-used for some other cleaning tasks
 *
 * Cleaning method described by the following articles:
 * http://pwndizzle.blogspot.fr/2014/07/breaking-facebooks-text-captcha.html
 * https://www.nulled.cr/topic/16772-facebook-captcha-ocr/
 *
 * PHP implementation by ORelio (c) 2016 - CDDL 1.0
 * http://opensource.org/licenses/CDDL-1.0
 * (do wtf you want but if improving please contribute back)
 * (http://qstuff.blogspot.fr/2007/04/why-cddl.html)
 */
 
// ====== SCRIPT CONFIG ====== //
   $tesseract_cmd = '/usr/local/bin/tesseract';
   $tmp_dir = '/tmp/';
// tessdata\configs\fb file must exist and contain the following line:
// tessedit_char_whitelist abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890
// ========================== //

// Resize and destroy input

function resize_replace($img, $ratio)
{
    $width = imagesx($img);
    $height = imagesy($img);
    $new_img = imagecreatetruecolor($width * $ratio, $height * $ratio);
    imagecopyresized($new_img, $img, 0, 0, 0, 0, $width * $ratio, $height * $ratio, $width, $height);
    imagedestroy($img);
    return $new_img;
}

// Binarization - Transform image to monochrome black/white

function binarize($img)
{
    $white = imagecolorallocate($img, 255, 255, 255);
    $black = imagecolorallocate($img, 0, 0, 0);
    $width = imagesx($img);
    $height = imagesy($img);
    for ($x = 0; $x < $width; $x++)
    {
        for ($y = 0; $y < $height; $y++)
        {
            $rgb = imagecolorat($img, $x, $y);
            $r = ($rgb >> 16) & 0xFF;
            $g = ($rgb >> 8) & 0xFF;
            $b = $rgb & 0xFF;
            $gray = ($r + $g + $b) / 3;
            if ($gray > 127)
                imagesetpixel($img, $x, $y, $white);
            else imagesetpixel($img, $x, $y, $black);
        }
    }
}

// Utility function for image cleaning : count adjacent pixels

function has_adjacent($img, $x, $y, $width, $height, $color, $amount = 1)
{
    $count = 0;
    foreach (array($x - 1, $x, $x + 1) as $tx)
        if ($tx >= 0 && $tx < $width)
            foreach (array($y - 1, $y, $y + 1) as $ty)
                if ($ty >= 0 && $ty < $height)
                    if (imagecolorat($img, $tx, $ty) == $color)
                        if (++$count >= $amount)
                            return true;
    return false;
}

// Border removal and expanding

function transform_area($img, $white, $black, $passes = 1)
{
    $red = imagecolorallocate($img, 255, 0, 0);
    $width = imagesx($img);
    $height = imagesy($img);
    for ($i = 0; $i < $passes; $i++)
    {
        for ($x = 0; $x < $width; $x++)
                for ($y = 0; $y < $height; $y++)
                    if (imagecolorat($img, $x, $y) == $black)
                        if (has_adjacent($img, $x, $y, $width, $height, $white))
                            imagesetpixel($img, $x, $y, $red);
        for ($x = 0; $x < $width; $x++)
            for ($y = 0; $y < $height; $y++)
                if (imagecolorat($img, $x, $y) == $red)
                    imagesetpixel($img, $x, $y, $white);
    }
}

function shrink_black_areas($img, $passes = 1)
{
    $white = imagecolorallocate($img, 255, 255, 255);
    $black = imagecolorallocate($img, 0, 0, 0);
    transform_area($img, $white, $black, $passes);
}

function enlarge_black_areas($img, $passes = 1)
{
    $white = imagecolorallocate($img, 255, 255, 255);
    $black = imagecolorallocate($img, 0, 0, 0);
    transform_area($img, $black, $white, $passes);
}

// Noise removal

function noise_cleanup($img, $bg_color, $passes = 1)
{
    $red = imagecolorallocate($img, 255, 0, 0);
    $width = imagesx($img);
    $height = imagesy($img);
    for ($i = 0; $i < $passes; $i++)
        for ($x = 0; $x < $width; $x++)
            for ($y = 0; $y < $height; $y++)
                if (imagecolorat($img, $x, $y) != $bg_color)
                    if (has_adjacent($img, $x, $y, $width, $height, $bg_color, 5))
                        imagesetpixel($img, $x, $y, $bg_color);
}

function black_noise_cleanup($img, $passes = 1)
{
    $white = imagecolorallocate($img, 255, 255, 255);
    noise_cleanup($img, $white, $passes);
}

// Main entry point

function ExtractFromDelimiters($string, $start, $end) {
    if (strpos($string, $start) !== false) {
        $section_retrieved = substr($string, strpos($string, $start) + strlen($start));
        $section_retrieved = substr($section_retrieved, 0, strpos($section_retrieved, $end));
        return $section_retrieved;
    } return false;
}

echo "rss-bridge facebook captcha solver by ORelio - v1.0\n";
ini_set('user_agent', 'CaptchaSolver/1.0');
stream_context_set_default(
    array('http' => array(
        'ignore_errors' => true)
    )
);

// Arguments?

if (count($argv) > 1)
{
    echo "URL $argv[1]\n";

    $url = $argv[1];
    $maxtries = 1;
    if (count($argv) > 2)
        $maxtries = intval($argv[2]);
    for ($try = 1; ; $try++)
    {
        echo "Captcha solving attempt $try of $maxtries\n";
        $page = file_get_contents($url, false);
        if (strpos($page, '<h2>Facebook captcha challenge</h2>') !== false)
        {
            echo " > Captcha detected.\n";
            
            $img_base64 = ExtractFromDelimiters($page, '<img src="data:image/png;base64,', '"');
            file_put_contents($tmp_dir.'captcha_input.jpg', base64_decode($img_base64));
            $img = resize_replace(imagecreatefromjpeg($tmp_dir.'captcha_input.jpg'), 2);
            unlink($tmp_dir.'captcha_input.jpg');            

            echo " > Cleaning captcha...\n";
            
            binarize($img);
            shrink_black_areas($img, 4);
            black_noise_cleanup($img, 5);
            enlarge_black_areas($img, 4);
            $img = resize_replace($img, 0.5);
            imagejpeg($img, $tmp_dir.'captcha_output.jpg');
            imagedestroy($img);
            
            echo " > Running OCR software...\n";
            
            exec($tesseract_cmd.' '.$tmp_dir.'captcha_output.jpg '.$tmp_dir.'captcha_output -psm 8 nobatch fb');
            $captcha_response = trim(file_get_contents($tmp_dir.'captcha_output.txt'));
            unlink($tmp_dir.'captcha_output.jpg');
            unlink($tmp_dir.'captcha_output.txt');
            
            echo " > Submitting response: $captcha_response\n";
            
            $php_session = ExtractFromDelimiters(implode($http_response_header), 'Set-Cookie: ', ';');
            $http_options = array(
            'http' => array(
                'method'  => 'POST',
                'header' => array("Content-type: application/x-www-form-urlencoded\r\nCookie: $php_session\r\n"),
                'content' => http_build_query(array('captcha_response' => $captcha_response)),
                'ignore_errors' => true
                ),
            );
            $context = stream_context_create($http_options);
            $page = file_get_contents($url, false, $context);
            if (strpos($page, '<h2>Facebook captcha challenge</h2>') === false)
            {
                echo " > Successfully solved! :)\n";
                exit(0);
            }
            else
            {
                echo " > Failed to solve the captcha. :(\n";
                if ($try == $maxtries)
                    exit(1);
            }
        }
        else
        {
            echo " > No captcha in the specified page. :)\n";
            exit(0);
        }
    }
}
else
{
    echo "Usage: php $argv[0] <url of stuck facebook rss-bridge> [attempts=1]\n";
    exit(2);
}

?>