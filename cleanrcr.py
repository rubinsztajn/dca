#!/usr/bin/env python
"""
cleanrcr.py
-----------------
A script for Rediscovery -> CIDER migration

Takes a CIDER import file of RCRs generated by rediscovery and translate the naughty bits from rediscov 
so it can be imported cleanly.

Usage:
cleanrcr.py /path/to/inputfile.xml /path/to/outputfile.xml
"""

import sys
from lxml import etree

input_xml = sys.argv[1]
output_xml = sys.argv[2]


def collapse_date(end_date):
    """ 
    grabs the start date, clears the children of <date>, and adds the start
    date to as the text of <date> and returns <date> for further processing
    """
    start_date = end_date.getprevious()
    date = end_date.getparent()
    date.clear()
    date.text = start_date.text
    return date
    
def main():

    tree = etree.parse(input_xml)
    out = open(output_xml, 'w')

    # clean audit trail date formatting
    timestamps = tree.xpath('//timestamp')
    
    for timestamp in timestamps:
        funky = timestamp.text
        dateparts = funky.split('/')
        fresh = dateparts[2] + '-' + dateparts[0] + '-' + dateparts[1]
        timestamp.text = fresh
        
    # fix audit trail names
        
    # the name map will eventually be maintained externally as part of the 
    # migration toolkit
        
    name_map = {
        'KSF': {'first':'Krista','last':'Ferrante'},
        'JP' : {'first':'Jennifer','last':'Phillips'},
        'VAM' : {'first':'Veronica','last':'Martzhal'},
        'ADR' : {'first':'Aaron','last':'Rubinstein'}
        }
        
    firstnames = tree.xpath('//staff/firstName')
    lastnames = tree.xpath('//staff/lastName')
        
    for firstname in firstnames:
        fullname = name_map[firstname.text]['first']
        firstname.text = fullname
        
    for lastname in lastnames:
        fullname = name_map[lastname.text]['last']
        lastname.text = fullname
        
    # clean up end date craziness
    end_dates = tree.xpath('//recordContext/date/to')
        
    for end_date in end_dates:
        if end_date.text == '2099-12-31' or '9999-99-99':
            date = collapse_date(end_date)
            # create ongoing element
            ongoing = etree.Element('ongoing')
            ongoing.text = 'true'
            # insert element after the date element (index = 4)
            rc = date.getparent()
            rc.insert(4, ongoing)
                        
    # split abstracts out of <history>
    histories = tree.xpath('//history')
                        
    for history in histories:
        # check for abstract delimiter and if present, split content accordingly
        if (history.text is not None) and (history.text.find(" __") != -1):
            history_parts = history.text.split(" __")
            # create <abstract> and set text
            abstract = etree.Element('abstract')
            abstract.text = history_parts[0]

            # insert abstract before history (index = 5 if <ongoing>, else 4)
            previous_elem = history.getprevious()
            if previous_elem.tag == 'ongoing':
                index = 5
            else:
                index = 4

            rc = history.getparent()
            rc.insert(index, abstract)

            # then reset <history> to include just the history without abstract
            history.text = history_parts[1]
        
    # split multiple sources into their own <source> element
    source_elems = tree.xpath('//source')

    for source in source_elems:
        # if <source> content has the rediscov source delimiter (--) split each citation and put it in a separate <source> element
        if source.text.find(' --') != -1:
            citations = source.text.split(' --')
            sources = source.getparent()
            sources.clear()
            for citation in citations:
                etree.SubElement(sources, 'source').text = citation

    # write modified XML tree to output file
    out.write(etree.tostring(tree, pretty_print=True))


if __name__ == '__main__':
    main()

