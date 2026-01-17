# streamlit/debug_supabase.py
import streamlit as st
from supabase import create_client
from dotenv import load_dotenv
import os

load_dotenv()

st.title("Supabase Debug Panel")

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

st.write("URL Loaded:", bool(SUPABASE_URL))
st.write("KEY Loaded:", bool(SUPABASE_KEY))

if SUPABASE_URL and SUPABASE_KEY:
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    st.success("Supabase client created")
