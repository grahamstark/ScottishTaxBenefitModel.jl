#
#!!! GENERATED DATA IS ALL GARBAGE !!!
#
# 
# sudo apt install python3-venv
# python venv ~/python3-sdv
# ~/python3-sdv/bin/pip install sdv
# ~/python3-sdv/bin/python 
# 
import sdv

import os
from sdv.datasets.local import load_csvs

import pandas as pd

from sdv.metadata import Metadata
from sdv.single_table import GaussianCopulaSynthesizer, CTGANSynthesizer, TVAESynthesizer
from sdv.io.local import CSVHandler
from sdv.multi_table import HMASynthesizer
from sdv.utils import poc



DATA_DIR= os.path.join("/", "mnt","data","Northumbria", "minitax" )
ACTUAL_DATA_DIR = os.path.join(DATA_DIR,'actual_data')
SAMPLE_DATA_DIR = os.path.join(DATA_DIR,'samples','5000')
SYNTH_DATA_DIR = os.path.join(DATA_DIR,'synthetic')


# ??? How to tab
# Direct tp PANDAS 
sp = pd.read_csv( os.path.join(ACTUAL_DATA_DIR,"simple_pers.tab"), sep='\t')
sh = pd.read_csv( os.path.join(ACTUAL_DATA_DIR,"simple_hhlds.tab"), sep='\t')

psize = sh.shape[0]

# 1 ==== single table test =====

sh_meta = Metadata()
sh_meta.detect_from_dataframe(sh)
# uhid needs to be id type for it to be pk
sh_meta.update_column( column_name='hno', sdtype='id' )
sh_meta.set_primary_key(column_name='hno')
sh_meta.save_to_json( os.path.join(ACTUAL_DATA_DIR,"sh_meta.json") )

# check for un-parsed columns
sh_meta.get_column_names(sdtype='unknown')

sh_synthesizer_g = GaussianCopulaSynthesizer(sh_meta) # statistical one
sh_synthesizer_c = CTGANSynthesizer(sh_meta) # deep learning one
sh_synthesizer_t = TVAESynthesizer(sh_meta)

# Step 2: Train the synthesizer

sh_synthesizer_g.fit(sh) # about 1 minute
sh_synthesizer_c.fit(sh)
sh_synthesizer_t.fit(sh)

# Step 3: Generate synthetic data
synthetic_sh_g = sh_synthesizer_g.sample(num_rows=psize) 
synthetic_sh_g.to_csv( os.path.join(SYNTH_DATA_DIR,"simple_hhlds_g.tab" ), sep='\t')


# Step 3: Generate synthetic data
synthetic_sh_c = sh_synthesizer_c.sample(num_rows=psize) 
synthetic_sh_c.to_csv( os.path.join(SYNTH_DATA_DIR,"simple_hhlds_c.tab" ), sep='\t')

# Step 3: Generate synthetic data
synthetic_sh_t = sh_synthesizer_t.sample(num_rows=psize) 
synthetic_sh_t.to_csv( os.path.join(SYNTH_DATA_DIR,"simple_hhlds_t.tab" ), sep='\t')

# 2 === Multi Table Test ===
#
# see: https://docs.sdv.dev/sdv/multi-table-data/modeling
#
connector = CSVHandler()
data = connector.read(
    folder_name=ACTUAL_DATA_DIR,
    file_names=['simple_hhlds.tab', 'simple_pers.tab'],
    read_csv_parameters={'sep':'\t'})

metadata = Metadata.detect_from_dataframes(data=data )
metadata.save_to_json(filepath=os.path.join(ACTUAL_DATA_DIR,'minitax-data--EDIT-ME.json'))
metadata = Metadata.load_from_json(os.path.join(ACTUAL_DATA_DIR,'minitax-data.json'))
# Step 1: Create the synthesizer
synthesizer = HMASynthesizer(metadata)
# Don't add primary key to 2nd table!!! WTF..
# Invalid relationship between table 'simple_hhlds' and table 'simple_pers'. A relationship must connect a primary key with a non-primary key.
synthesizer.fit(data)
synthetic_data = synthesizer.sample()
connector.write(
  synthetic_data,
  folder_name=SYNTH_DATA_DIR,
  to_csv_parameters={
      'sep': '\t',
      'index': False},
  file_name_suffix='_v1', 
  mode='x')
#
#!!! DATA IS ALL GARBAGE !!!
#