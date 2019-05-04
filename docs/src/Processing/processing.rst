#########################
Data Processing Functions
#########################
Supported processing operations are described below. Functions are organized
categorically.

In most cases, a "safe" version of each function can be invoked to create a
new SeisData object with the processed output.

Any function that can logically operate on a SeisChannel object will do so. Any
function that operates on a SeisData object will also operate on a SeisEvent
object by applying itself to the SeisData object in the ``:data`` field.

*****************
Signal Processing
*****************

.. function: demean!(S::SeisData[, irr=false])

Remove the mean from all channels i with S.fs[i] > 0.0. Specify irr=true to also
remove the mean from irregularly sampled channels. Ignores NaNs.

.. function: detrend!(S::SeisData[, n=1, irr=false])

Remove the polynomial trend of degree n from every regularly-sampled channel i
in S using a least-squares polynomial fit. Ignores NaNs.

.. function:: equalize_resp!(S, resp_new::Array[, hc_new=HC, C=CH])

Translate all data in SeisData structure **S** to instrument response **resp_new**.
Expected structure of **resp_new** is a complex Float64 2d array with zeros in
**resp[:,1]**, poles in **resp[:,2]**. If channel **i** has key **S.misc[i]["hc"]**,
the corresponding value is used as the critical damping constant; otherwise a
value of 1.0 is assumed.

.. function:: filtfilt!(S::SeisData[; KWs])

Apply a zero-phase filter to data in **S.x**.

.. function:: filtfilt!(Ev::SeisEvent[; KWs])

Apply zero-phase filter to **Ev.data.x**.

.. function:: filtfilt!(C::SeisChannel[; KWs])

Apply zero-phase filter to **C.x**

Filtering is applied to each contiguous data segment of each channel separately.

### Keywords
Keywords control filtering behavior; specify e.g. filtfilt!(S, fl=0.1, np=2, rt="Lowpass").
Default values can be changed by adjustin the :ref:`shared keywords<dkw>`, e.g.,
SeisIO.KW.Filt.np = 2 changes the default number of poles to 2.

.. csv-table::
  :header: KW, Default, Type, Description
  :delim: |
  :widths: 1, 2, 1, 4

  fl  | 1.0           | Float64 | lower corner frequency [Hz] \ :sup:`(a)`
  fh  | 15.0          | Float64 | upper corner frequency [Hz] \ :sup:`(a)`
  np  | 4             | Int64   | number of poles
  rp  | 10            | Int64   | pass-band ripple (dB)
  rs  | 30            | Int64   | stop-band ripple (dB)
  rt  | \"Bandpass\"    | String  | response type (type of filter)
  dm  | \"Butterworth\" | String  | design mode (name of filter)

:sup:`(a)`  By convention, the lower corner frequency (fl) is used in a Highpass
filter, and fh is used in a Lowpass filter.

.. function:: taper!(S)

Cosine taper each channel in S around time gaps.

.. function:: unscale!(S[, irr=false])

Divide the gains from all channels **i** with **S.fs[i] > 0.0**. Specify **irr=true** to
also remove gains of irregularly-sampled channels.

.. _merge:


***********************
Merge and Synchronize
***********************

.. function:: merge!(S::SeisData, U::SeisData)

Merge two SeisData structures. For timeseries data, a single-pass merge-and-prune
operation is applied to value pairs whose sample times are separated by less than
half the sampling interval.

.. function:: merge!(S::SeisData)

"Flatten" a SeisData structure by merging data from identical channels.

Merge Behavior
==============
Two (or more) channels are merged if they have the same values for each of
these fields:
+ ``:id``
+ ``:fs``
+ ``:resp``
+ ``:units``
+ ``:loc``
Unset (empty) values for ``:resp``, ``:units``, and ``:loc`` are treated as a
match to any non-empty value in the corresponding field.

How Merges Work
---------------
* Non-overlapping data are concatenated and time gaps are adjusted as needed.
* Redundant data are removed.
* Data that overlap in time and have different values are averaged pairwise if
  x\ :sub:`i`\ , x\ :sub:`j`\  : \| t\ :sub:`i`\ -t\ :sub:`j`\  \| < (0.5*S.fs). Warnings are thrown
  when this situation is encountered.

It's best to merge only unprocessed data. Merging data segments that were
processed independently (e.g. detrended) throws many warnings if values differ
at overlapping times.

When SeisIO Won't Merge
------------------------
SeisIO does **not** combine data channels if **any** of the five fields above
are non-empty and different. For example, if a SeisData object S contains two
channels, each with id "XX.FOO..BHZ", but one has fs=100 Hz and the other fs=50 Hz,
**merge!** does nothing.

.. function:: sync!(S::SeisData)

Synchronize the start times of all data in S to begin at or after the last
start time in S.

.. function:: sync!(S::SeisData[, s=ST, t=EN, v=VV])

Synchronize all data in S to start at `ST` and terminate at `EN` with verbosity level VV.

For regularly-sampled channels, gaps between the specified and true times
are filled with the mean; this isn't possible with irregularly-sampled data.

Specifying start time (s)
-------------------------
* s="last": (Default) sync to the last start time of any channel in `S`.
* s="first": sync to the first start time of any channel in `S`.
* A numeric value is treated as an epoch time (`?time` for details).
* A DateTime is treated as a DateTime. (see Dates.DateTime for details.)
* Any string other than "last" or "first" is parsed as a DateTime.

Specifying end time (t)
-----------------------
* t="none": (Default) end times are not synchronized.
* t="last": synchronize all channels to end at the last end time in `S`.
* t="first" synchronize to the first end time in `S`.
* numeric, datetime, and non-reserved strings are treated as for `-s`.


.. function:: mseis!(S::SeisData, U::SeisData, ...)

Merge multiple SeisData structures into S.

**************************
Other Processing Functions
**************************

.. function:: nanfill!(S)

For each channel **i** in **S**, replace all NaNs in **S.x[i]** with the mean
of non-NaN values.

.. function:: ungap!(S[, m=true])

For each channel **i** in **S**, fill time gaps in **S.t[i]** with the mean of
non-NAN data in **S.x[i]**. If **m=false**, gaps are filled with NANs.
