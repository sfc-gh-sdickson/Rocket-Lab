import os
import streamlit as st

st.set_page_config(page_title="Rocket Lab Component Life", layout="wide")

conn = st.connection("snowflake", ttl=os.getenv("SNOWFLAKE_CONNECTION_TTL"))


@st.cache_data
def load_rul_data():
    return conn.query("""
        SELECT VEHICLE_NAME, VEHICLE_TYPE, COMPONENT_TYPE, COMPONENT_NAME,
               COMPONENT_STATUS, LIFE_USED_PCT, INSPECTION_RUL_CYCLES AS RUL_CYCLES,
               SUPPLIER_NAME, QUALITY_RATING
        FROM ROCKET_LAB_INTELLIGENCE.ANALYTICS.COMPONENT_HEALTH
        WHERE COMPONENT_STATUS <> 'Flown'
        ORDER BY INSPECTION_RUL_CYCLES
    """)


st.title("Component Remaining Useful Life")
st.caption("Inspector estimate of cycles left on hardware that has not yet flown")

df = load_rul_data()
if df.empty:
    st.warning("No component health data found.")
    st.stop()

urgent = int((df["COMPONENT_STATUS"].isin(["Failed", "Needs Replacement"])).sum())
c1, c2, c3 = st.columns(3)
c1.metric("Live components", f"{len(df):,}")
c2.metric("Failed or needs replacement", f"{urgent:,}")
c3.metric("Median cycles remaining", f"{df['RUL_CYCLES'].median():.0f}")

st.subheader("Average cycles remaining by vehicle")
by_vehicle = (df.groupby(["VEHICLE_NAME", "VEHICLE_TYPE"])["RUL_CYCLES"].mean()
              .reset_index().sort_values("RUL_CYCLES"))
st.bar_chart(by_vehicle.set_index("VEHICLE_NAME")["RUL_CYCLES"], horizontal=True,
             height=max(400, len(by_vehicle) * 22))

st.subheader("Component detail")
types = st.multiselect("Vehicle type", sorted(df["VEHICLE_TYPE"].unique()),
                       default=sorted(df["VEHICLE_TYPE"].unique()))
shown = df[df["VEHICLE_TYPE"].isin(types)]
st.dataframe(shown[["VEHICLE_NAME", "VEHICLE_TYPE", "COMPONENT_NAME", "COMPONENT_STATUS",
                    "RUL_CYCLES", "LIFE_USED_PCT", "SUPPLIER_NAME", "QUALITY_RATING"]],
             use_container_width=True, hide_index=True)

if st.button("Refresh data"):
    load_rul_data.clear()
    st.rerun()
