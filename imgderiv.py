#!/usr/bin/env python

"""
Script for generating derivative images for the Image.4DS content model.
Should detect the orientation of the original image and scale accordingly.
Currently requires ImageMagick installed and in your PATH as well as 
PIL, which is used to determine the image dimensions and generate thumbnails.

$ imgderiv.py path/to/images

"""

import sys, os
from shutil import copy2
from PIL import Image

dir = sys.argv[1]

def make_derivs(deriv_type, image, filename):

    name, ext = os.path.splitext(filename)
    x, y = image.size

    if deriv_type == 'archival':
        deriv_name = 'archival/' + name + '.' + deriv_type + ext
        try:
            copy2(filename, deriv_name)
        except IOError, e:
            print "IOError", filename

    elif deriv_type == 'advanced':
        deriv_name = 'advanced/' + name + '.' + deriv_type + '.jpg'
        im_cmd = "convert " + filename + " " + deriv_name
        os.system(im_cmd)

    elif deriv_type == 'thumb':
        image.thumbnail((120, 120), Image.ANTIALIAS)
        image.save('thumb/' + name + '.' + deriv_type + '.png')

    elif deriv_type == 'basic':
        deriv_name = 'basic/' + name + '.' + deriv_type + '.jpg'
        if x > y:
            constrain = "600"
        elif x < y:
            constrain = "x600"
        im_cmd = "convert -resize " + constrain + " " + filename + " " + deriv_name
        os.system(im_cmd)


def main():

    new_dirs = ['archival', 'advanced', 'basic', 'thumb']

    for new_dir in new_dirs:
        os.mkdir(new_dir)
    
    for filename in os.listdir(dir):
        if not os.path.isdir(filename):

            im = Image.open(filename)
            
            # generate derivatives
            make_derivs('archival', im, filename)
            make_derivs('advanced', im, filename)
            make_derivs('basic', im, filename)
            make_derivs('thumb', im, filename)
        
if __name__ == '__main__':
    main()

            
            
            
            
        
