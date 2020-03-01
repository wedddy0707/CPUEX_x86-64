#!/bin/env python
# you need to run the following command:
# pip install pyelftools

from __future__ import print_function
import sys

from elftools.elf.elffile import ELFFile
from elftools.elf.relocation import RelocationSection

template = '''memory_initialization_radix=16;
memory_initialization_vector={};
radix=16;'''

def process_file(input_filename, output_filename):   
   with open(input_filename, 'rb') as f:
      elffile = ELFFile(f)
      sections_unsorted = []       
      data = list(filter(lambda x: 'text' in x.name, elffile.iter_sections()))[0].data()

   s = ""
   for i in range(0, len(data)):
      s += "{:02x}".format(ord(data[i]))
      if i % 8 == 7:
         s += ","
         
   with open(output_filename, 'wb') as f:
      f.write(template.format(s))
      
def main():
   if len(sys.argv) == 3:
      process_file(sys.argv[1], sys.argv[2])
   else:
      print("{} <input> <output>".format(sys.argv[0]))
       
if __name__ == '__main__':
   main()
