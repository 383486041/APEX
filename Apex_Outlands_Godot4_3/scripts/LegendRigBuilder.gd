class_name LegendRigBuilder
extends RefCounted
## ============================================================================
## GENERATION 5.0: 12-LEGEND BESPOKE 3D ARMOR/SYLHOUETTE OVERHAUL & LOSSLESS
## 65-BONE 30FPS MOCAP ENGINE (`ual_mocap_bank.bin` + `Mannequin_F.glb` + `UAL1/2`)
## ============================================================================
## Key Features:
## 1. Lossless 65-Bone 30FPS Mocap Bank (`res://assets/animations/ual_mocap_bank.bin`):
##    Directly poses all 65 bones of `Skeleton3D` every frame from 33 motion-captured
##    clips in `UAL1_Standard.glb` & `UAL2_Standard.glb`, completely bypassing Godot's
##    `remove_immutable_tracks` stripping and `AnimationPlayer` path-binding issues!
## 2. True 12-Legend Visual Differentiation (`全12位传奇角色差异化建模`):
##    - Female Legends (`wraith`, `lifeline`, `bangalore`, `ash`, `horizon`, `valkyrie`)
##      use the sculpted female mesh (`Mannequin_F.glb`).
##    - Male & Robotic Legends (`bloodhound`, `pathfinder`, `octane`, `gibraltar`,
##      `caustic`, `mirage`) use `UAL1_Standard.glb`.
##    - Distinct per-Legend body proportions (`legend_scale`), 2-tone base materials,
##      and 10-zone bone-attached 3D helmets/hair, chest cuirasses, jetpacks/wings/drones,
##      waist coats/kilts/aprons, shoulder pauldrons, forearm gauntlets, baggy cargo pants,
##      and prosthetic/robotic lower legs!
## 3. Fixes All 6 Animation & Unified 1P/3P Camera Requirements:
##    - Reload (`Pistol_Reload`) is driven 1:1 by `reload_progress` (`0.0 -> 1.0`) so it
##      plays strictly ONCE and never repeats.
##    - Jump landing, Slide exit (`Slide_Loop`), and Wall-Climb (`ClimbUp_1m`) reset all
##      65 bones cleanly every frame with zero residual stuck poses.
##    - Full lower-body `Walk_Loop`, `Jog_Fwd_Loop`, and `Sprint_Loop` combined with
##      pelvis-compensated upper-body weapon aiming.
##    - Unified 1st-person & 3rd-person character hands and weapons with zero head clipping.
## ============================================================================

const BONE_NAMES_65: Array = [
	"root", "pelvis", "spine_01", "spine_02", "spine_03", "neck_01", "Head",
	"clavicle_l", "upperarm_l", "lowerarm_l", "hand_l",
	"index_01_l", "index_02_l", "index_03_l", "index_04_leaf_l",
	"middle_01_l", "middle_02_l", "middle_03_l", "middle_04_leaf_l",
	"pinky_01_l", "pinky_02_l", "pinky_03_l", "pinky_04_leaf_l",
	"ring_01_l", "ring_02_l", "ring_03_l", "ring_04_leaf_l",
	"thumb_01_l", "thumb_02_l", "thumb_03_l", "thumb_04_leaf_l",
	"clavicle_r", "upperarm_r", "lowerarm_r", "hand_r",
	"index_01_r", "index_02_r", "index_03_r", "index_04_leaf_r",
	"middle_01_r", "middle_02_r", "middle_03_r", "middle_04_leaf_r",
	"pinky_01_r", "pinky_02_r", "pinky_03_r", "pinky_04_leaf_r",
	"ring_01_r", "ring_02_r", "ring_03_r", "ring_04_leaf_r",
	"thumb_01_r", "thumb_02_r", "thumb_03_r", "thumb_04_leaf_r",
	"thigh_l", "calf_l", "foot_l", "ball_l", "ball_leaf_l",
	"thigh_r", "calf_r", "foot_r", "ball_r", "ball_leaf_r"
]

# Bone indices (in BONE_NAMES_65) for upper-body firearm aiming overlay (spine_02..thumb_04_leaf_r)
const ACTIVE_22_BONES: Array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 31, 32, 33, 34, 55, 56, 57, 58, 60, 61, 62, 63]

const MOCAP_CLIPS_META: Dictionary = {
	"Idle_Loop": {"offset": 263, "frames": 16, "dur": 2.5000},
	"Pistol_Idle_Loop": {"offset": 1719, "frames": 16, "dur": 1.6667},
	"Pistol_Shoot": {"offset": 3175, "frames": 10, "dur": 0.6333},
	"Pistol_Reload": {"offset": 4085, "frames": 24, "dur": 1.6667},
	"Walk_Loop": {"offset": 6269, "frames": 18, "dur": 1.3333},
	"Jog_Fwd_Loop": {"offset": 7907, "frames": 18, "dur": 0.9333},
	"Sprint_Loop": {"offset": 9545, "frames": 16, "dur": 0.6667},
	"Crouch_Idle_Loop": {"offset": 11001, "frames": 14, "dur": 2.9333},
	"Crouch_Fwd_Loop": {"offset": 12275, "frames": 18, "dur": 2.0000},
	"Jump_Start": {"offset": 13913, "frames": 14, "dur": 1.3333},
	"Jump_Loop": {"offset": 15187, "frames": 14, "dur": 2.5000},
	"Jump_Land": {"offset": 16461, "frames": 14, "dur": 1.2667},
	"Punch_Jab": {"offset": 17735, "frames": 14, "dur": 0.8667},
	"Punch_Cross": {"offset": 19009, "frames": 14, "dur": 1.0000},
	"Sword_Idle": {"offset": 20283, "frames": 14, "dur": 1.6667},
	"Sword_Attack": {"offset": 21557, "frames": 16, "dur": 1.5333},
	"Hit_Chest": {"offset": 23013, "frames": 10, "dur": 0.3333},
	"Death01": {"offset": 23923, "frames": 18, "dur": 2.4000},
	"Slide_Start": {"offset": 25561, "frames": 12, "dur": 0.8333},
	"Slide_Loop": {"offset": 26653, "frames": 16, "dur": 2.0000},
	"Slide_Exit": {"offset": 28109, "frames": 10, "dur": 0.5000},
	"ClimbUp_1m": {"offset": 29019, "frames": 16, "dur": 0.6667},
	"Consume": {"offset": 30475, "frames": 16, "dur": 1.3333},
	"NinjaJump_Start": {"offset": 31931, "frames": 14, "dur": 0.9667},
	"NinjaJump_Idle_Loop": {"offset": 33205, "frames": 14, "dur": 2.0000},
	"NinjaJump_Land": {"offset": 34479, "frames": 14, "dur": 1.2667},
	"Melee_Hook": {"offset": 35753, "frames": 14, "dur": 0.4667},
	"Sword_Regular_A": {"offset": 37027, "frames": 14, "dur": 0.4333},
	"Sword_Regular_B": {"offset": 38301, "frames": 14, "dur": 0.5333},
	"Sword_Regular_C": {"offset": 39575, "frames": 16, "dur": 2.0000},
}

const MOCAP_FLOATS_B64: String = "Uns/O3KasD2Oi2A/9AQ1vwAAAAAAAAAA9AQ1PzUxQT8ShrS9rXqavetRJT/fgoS9uuvvq4dQwK+tdn8/SLXNO9ccXb2zG0689Zl/P7dMqj29WSG+rkSJvB/eez8VPwM+VgncPX5hxrrgZHw/HafgvHNvWD72bj88mRl6PydPKb9i5Vy+8H5kvqfOLj8Yo/w+UFK8PmnxOb+6spw+H7vIPl49eb4E8909dGlhP5srmrypfhy/JbqKPqRKPj9OMKi0IwU1P2hurrHDBDU/avqyPmolmrMvnt40btlvPyXehT6B+yu0U9O+NEcYdz8GAIAyAACAPwr/X7ELIXU2sL2uvevIMz+w3qS9F8EzP1wfzz45bQY91uRSvJLxaT9LIOQ+uu0DuiSRhLo7L2U/wf//MAAAgD9o/z8xCdF1NiVwfz6D0B0/+eHGvoNKIz+iZ9U+PkUAvpc1aj1zBGY/RWfXPvuKhjnjChE68T1oPwoA8DIAAIA/eP9/sQzRdDaW5ZY9t8omP15SvL6OzSg/Lq6xPsRWRb55upU9bzhqP69M5D5tTvm5q0V6ui8kZT8EAJgyAACAPzL837AMUXU21Vl9Ppcfcj/sUlA+6HpbPQA3Drn+bpu4XF1IOAAAgD+FwYE5NcKpOB43DLr9/38/ezqfMuCUAT/x3pM0J8hcP8NUAb9QCeo+xgIEP1YABT8fKjQ/d+CQvqOZET+M2aI+53DWPQEC8D6SsGW9sRNgP95pFT21qKQ+yCt1vS68cT9ksQW9odc0v4t/9Tw91zQ/sjLEPgVb6LzN4kA85FNsP7ilAT9D4c+z7c9jNUS+XD/6AMAwAACAv/v/ATILEXU2N8LHPhouDb8UZu4+6loSP03sBD/8dls9GvsMvZgtWj+q1pc++6avOQhKjTrHe3Q/AAASMgAAgL+ILQCuChV1NmFMFj/N9sq+CFcOP1SY3j6mPKY+CQ7nPdNEHL0fNHA/3puDPm9CJLkU/hm64WV3PwAAsDIAAIC/Gub/LQsBdTZiygw/JFLivhuvCT9oPOw+EnymPorexz3WVAq976NwPwcjyD6y79o5s8mAOq+haz/g/4kxAACAvw8AhbEKEnU2orbFvqZkaj/8f+U9z9n1OjSTcD6ymAy+dZ1mPoB/bz+Ho/Q+BHNBOe9xBTr04mA/lYqWMt6UAb8RCKC0KMhcP4D4dj/6IOQ9dQVhvIzVcz69VTo+bovlvSD9qjw6B3o/5wj9vgH6sjxm7r89LC9dP4XVDznP3Ha/LJKHPl3sAjoAAICyAYCvsgGAr6UAAIA/PVJ+P3+m572gfmQ8vwkWPL7N6j1tf7c+Pug1vYzpbD/1JhS/pl5NvaIsJ75OJUw/ysUPOc/cdr8tkoc+pOoCOgAAgLIBgK+yAoCvpQAAgD/DOa47+yOxPV6OYD+2hEE/GNS0vU8fmr0j8CQ/24KEvbnSebFUisAwrXZ/P+3yezzdHAI5S0iCOUD4fz8bGr09DN6jObbwhjkH6H4/g2CXPMlMeLlrIn65z/R/P6niirp7osQ9XuMxu/TQfj8IeRm/GDa/vjDVyb41hhY/Wa+SviBsLD/Q3P2+PUzvPgyEjz6Bpi89lj+gux19dT8bG9k9wuvQO/5S0rynd34/p7civ5D4nj5CwKg+gREgP7Kilr5KPy6/qUvwPgV89T7MCbw+wWAdviOafD1DTmo/KgXvPfYlPzvJaTc9q/19P03Cdj9oE+I97v5evNK3dz5QSj0+LJXlvVzUrTwR43k/zZz9vgFPtzyKEb09yw1dPwbYDznP3Ha/LJKHPoHrAjpcRn4/C2fqvZA1ZzyQVz08esnqPZWBtz475zW9NOlsP8PkE7/jcUu99OUnvrZNTD/LuA85z9x2vy2Shz4k6wI6LR6gO3KasD2tKGA/NTFBPxKGtL2tepq961ElP9+ChL0AEPCrkFDAr612fz9Y/g88vXMAOUohhDl4/X8/CqmvPZAKoTmPu4g5fA5/P3FYzTx80HS5rpaAuWjrfz/Q8xC8BbbEPaA/N7pnzn4/HBoavzhdvr7Mocq+SeEVPyooj77JNSw/J1QAv4AQ7z7akog+Ai8QPaIbDLskj3Y/HxvZPQvs0DsUU9K8p3d+PyFbI7+LS54+m2KpPqlqHz8lZpe+XnkuvzNf7j6aPvY+IvC7Ph5TIL5zqoA9Si5qPyUF7z2RJT87v2k3Pav9fT+blXY/p6zkPSiPYbyQ4nk+K5JFPkJV5L2kurQ8yn95P5JZ/75hgbo8RrO9Pc2KXD8S1g85z9x2vyyShz5W7AI68CN+P2jq8r08m288JqpjPGXaAD7rsLY+sv5GvXOkbD8AJBW/55ZPvZ/IJ75zYks/AsoPOc/cdr8skoc+k+oCOpYihDv/jLE9MllfP2LEQT+VD7W9ZdmZvVOlJD/dgoS9noVyMfLtN7Gtdn8/HbnbO4Dn/zhKtIQ5h/5/P69oqz38I6A5U0mJOQ4afz9yaN48nKxzuScQgbnX538/EG60vPi0xD1O6n46AcF+P+xxG79GiLy+Y1bMvpd8FD9GYIe+Yr4rP3M5A7+xpu4+RCSBPsTtmDzWoDE7AK13Px8b2T3N69A7MVPSvKd3fj8tuCS/idWcPhy9qj7nAR4/GumVvrsILr+UFPI+Q8f0PlEhvD5joBq+oy94PZFraj8jBe89qyU/O8NpNz2r/X0/E6B1PxvD6j1ukGe885qDPlSeWD5fv+G9XK3EPL6IeD/skwG/h1K8PNyvvj0pals/P9gPOc/cdr8skoc+PewCOr3AfT9tUwO+domBPDDw5DwQBBw+8ty0Pixab73+0ms/wgsYv3nSV71k+Ca+9zpJP0azDznP3Ha/LZKHPoHqAjq3Aj47iWSzPaqbXj8/4UI/yBm2vfmdmL3CUyM/14KEvWVJF64eqz+wrXZ/PzfCLzxD8AA54pSDOTr8fz+8nbM9XuShOX02iDl2A38/ane9PNXUdblIHYC5eO5/P02rB72zssQ9GbmmOtusfj9bshy/nMu6vi7tzb5JKhM/EaR/vsRKKz+GzwW/F1/uPgRFez5NzVQ7Qt3cO3gqeD8dG9k96uvQOwRT0rynd34/o/0lvwxzmz4aAKw+26scP0lKk77VRy2/vzn4PjtX8j4UcLw+LAURvlzEaD24zWo/GwXvPX4lPzvVaTc9q/19P0xwdD+f2/A9s5NtvKyBiz4O8mk+zW7fvcgN0zxkknc/TkIDvxmOujx56L893GVaPxLaDznP3Ha/LJKHPofrAjo1UX0/0rYLvpbPiTz45zQ91x80Pu9Gsz5cfom9QuZqP02kGr9hmF69EeAlvjtFRz+NtA85z9x2vyyShz456wI6dR/IOoCitD3IZV4/baBDP2rMtr3Sx5e9lW4iP9uChL1KNIOxFo98sK12fz9u7o48nqcCOfmngTkG9n8/x1LBPQfHpDmFXIY5XNt+P9Frhjyfanm5RAx9uS33fz/S/wW9U7bEPUDQbbi/rX4/IhQdv3BCur5Lac6+58ESPyrqer6dJis/wJMGv3VO7j7QFYE+m1O1ulYGAjy8uHc/GxvZPW/r0DsJU9K8p3d+P/tgJr+4BZs+rGKsPlhCHD+P/pC+xKMsvxpD/T7XVfA+Aa68Pqf8CL6e31s92xprPyMF7z34JD87v2k3Pav9fT/+4HM/XfHzPa6ecLxeCo8+tN5uPoe23r12Ddc82Eh3P9uzA7/j9bU8RmbBPSodWj+F1Q85z9x2vyyShz5d7AI6PCN9P9YGDr6OF4w8JiNVPTqzPD5ezLI+jOSPvXqCaj+aqBu/mD1hvY/3JL5Jg0Y/HskPOc/cdr8tkoc+Y+sCOqCCkjdyU7Q9lOdeP/ZwQz8ToLa9MP2Xva6nIj/dgoS9jYuCMfGp9y+tdn8/RH+8PCcSBDnsDIA5pu5/P8uqzD1QL6c5W9mEOey3fj9ErzE8+VV8uUdnerkl/H8/KnO8vBKqxD3YGQe7k79+P+VBHL+JaLu+bF7Nvq2hEz9hgYK+1HMrP2zqBL9Ade4+WI2IPk6MDzynzak7rbZ2Px8b2T0969A74FLSvKd3fj9liyW/IfCbPruOqz6NJB0/IMCQvpeSLL+vx/0+7yDwPji0vD4EJwi+gohaPZ0iaz8lBe89kiY/O7tpNz2r/X0/ZW90Pwuq8j3ZW2+8IVWLPoM1Yz6ZE+C9Kj7NPJf1dz/EhwK/ox6wPMsSwz2EzFo/t9cPOc/cdr8skoc+QewCOihmfT/kqwi+RM+GPJkiPT2cJzE+4a+zPmN9h70A+2o/vKAavwwOX70HiyS+J1lHP7i/DznP3Ha/LJKHPoDqAjrQlq66tjGzPey8Xz+fwkI/KP21vRbAmL1GeCM/2YKEvdl2/7HGdgQwrXZ/P981wTxqOAQ5Usx/OcXtfz+T1s09aG2nOTSrhDkltH4/g0IoPCmsfLkfMnq5i/x/P/E+F7wqlMQ9KWVluzLOfj/N3xq/lFC9vt2cy775FBU/dLmKvrTxKz8zAgK/A9DuPqWJjz6CpdI8hFEFOVmldT8dG9k9DuzQO+pS0rynd34/0SMkv0V1nT7YKao+AJweP5T1kr7pLy2/ZPj4Pm8L8j5mebw+f9cPviDgZj1R2Wo/HwXvPa0lPzvRaTc9q/19P/KMdT8que49n3hrvPW1gz7AW04+DJrivaGouzzsEnk/enMAv+rWqTyZmsQ9cQJcPxrXDznP3Ha/LJKHPlfsAjpr230/He/9vZh5ejwNmQU9R9EZPntPtT5bjGy98NZrP1VdGL+dvFm9XYQkvoYbST9DxQ85z9x2vy2Shz4f6wI6O9gSu6zUsT1ya2A/yu9BPyk4tb2gqZm9MHIkP9uChL1StIMx0EN8MK12fz/ppJU8YNcCOaBxgTkR9X8/fP7CPdQmpTmuIoY5RdZ+PwNrfzzL2Xm5/bF8uQn4fz+5H/U5ZZbEPWTbX7v80H4/C7gZv3nhvr43Jcq+3EUWP1tQkb7+Viw/Nvb+vho07z4Op5E+xTUjPSAAibtXNXU/FxvZPTfr0DsGU9K8p3d+P5v3Ir8KtZ4+v/+oPmfQHz+0wZW+Ov0tv0J08j5iofQ+Nia8Pk4MGr70QXc9qHFqPx0F7z13JT87x2k3Pav9fT9JnHY/HJvqPe9oZ7wkEng+stY6Plzs5L1F/6o8fQN6P5IC/b4XX6U8RbnFPTkfXT+d1w85z9x2vyyShz7f6wI6Aj9+P4mx6r0Tf2c8tkqTPCTlAT4927Y++NhIvZmRbD+V/BW/B/FTvbXJJL675Uo/hcYPOc/cdr8skoc++ekCOglMH7uCz7A9y3pgP3FRQT8upLS9cVeavTgsJT/bgoS9f4N+MQz3w6+tdn8/UGw2PNUBATnOc4M58Pt/PyJytD2/EKI5bBWIOR8Bfz8aI7o8YxJ2ueUBgLkU738/mCP3ugiuxD2Qp+663dB+PyWWGb8HD7++LPrJvoFoFj+FDZK+YmIsPxZf/r74QO8+8RKNPiwGKj38HYy7yNt1Pxkb2T0v69A7AVPSvKd3fj8y1SK/YtmePprdqD508x8/qWSXvu54Lr/2Yu4+Hz32PlTwuz5iTSC+5KWAPYkuaj8hBe89uiY/O71pNz2r/X0/Wft2P+fG6T2il2a8kEpyPvYwNz4fPOW9IsanPBAuej/7Vvy+rZmmPHgZxj2lTl0/ItcPOc/cdr8skoc+1+sCOjBVfj9uWea9HDZjPJjSQTxRavg9DSa3PvA6QL0lu2w/jGwVvyHmUr3EESW+VE1LP0PFDznP3Ha/LZKHPh/rAjq8Dui6aMewPSnbXz+GTEE/lp+0vdVcmr36MSU/2YKEvaWtgDHiWTGtrXZ/P+A93DtT1f84zLGEOYX+fz/0cKs9aiCgOVxKiTn3GX8/NEfePPStc7koD4G53ud/P4e6WbyJt8Q9wF4EOSrLfj9jmRq/l7C9vnFDy778XRU/7VCMviEKLD8wagG/2uXuPm9qhT51Tu487ouHuTELdz8lG9k9xevQO/5S0rynd34/VNwjv9XBnT7g4qk+2uUeP422lr4sRS6/IxrwPpiP9T49B7w+2KwdvlEUfT0QS2o/JQXvPbslPzvIaTc9q/19P8dsdj8YE+09Z9hpvDFqej7DBUc++SfjvZwotTyMcXk/UZf/vrJDrTzWdsU9WGBcP8jXDznP3Ha/LJKHPjLsAjqNE34/86r1vTdScjyMSZw8tO8OPrDWtT5uGFy9SzpsP+VNF79hIVi97CIlvrDhST8Tvg85z9x2vy2Shz4c6gI60nfUuZ9Dsj2QBF8/6DJCP9x2tb2JX5m96CIkP9mChL3BatSuVorfsK12fz+kjgw89G8AOds1hDmW/X8/fTuvPfPsoDmoyYg5qQ9/Px8QzzxjsHS5QKiAuQ/rfz98H+e8XbPEPUyjnjrFtn4/NQAcv7zDu74LC82+E+cTP40OhL6Siys/+WIEv7GD7j4qCH4+hI9BPEfXlDvu+Xc/GxvZPZfr0Dv5UtK8p3d+P61IJb/YOJw+ikyrPrhqHT99Y5S+55ctv3i09T6GV/M+MlC8Pmb8FL7kIW89+6VqPywF7z0/Jj87x2k3Pav9fT/gN3U/CmLxPVEYbryy3IU+v0JdPvl74L2H9sc8NEt4P+EBAr9uHLM8I9fDPdUYWz+61g85z9x2vyyShz696wI6ap99P1CEBb63soM8tHoPPaTqKD5bEbQ+3kOBvV1Xaz/p1hm/fh1evUgGJb7D70c/bb0POc/cdr8tkoc+s+oCOrmIqTp2C7Q9Zm9eP7VFQz+kd7a9ry2YvZjbIj/hgoS9O8d1sYcZADGtdn8/qo9wPIzvATmBb4I58Ph/PyKvuz32l6M5wh6HOTjsfj+IEp08cvF3uS9afrnz838/a4sSvRK1xD02vUk61qZ+Pxr/HL//X7q+mE7OvmnYEj+Z73u+bi4rP8dpBr/SUe4+fn58Pvgc3bn+ZPs7ehZ4Pysb2T2s69A7FFPSvKd3fj+dSya/RR2bPnZNrD4XWRw/KMSRvnXaLL8Pmvs+SP/wPtqZvD7apgu+dyZgPcQBaz8sBe89xyU/O8VpNz2r/X0/YR10Pzuw8z1oXnC8HnONPs4YbT4I0d69rXbVPBxkdz/diwO/UpS2PN2+wT3vM1o/VNgPOc/cdr8skoc+LOwCOi02fT9jGg2+Ui6LPH82SD0ZeDo+geayPh01jr0onmo/Q3Ubv2AZYb0CDyW+capGP0PFDznP3Ha/LZKHPh/rAjrNwT879Ke0PeaHXj+vo0M/ds+2vSbEl72oaiI/2YKEvXJ+g7EbB/evrXZ/P8BurTx2jgM5l5aAOVDxfz826sg9+GemOaNWhTnew34/gNVPPDNce7mJVXu5ufp/P+hA/Lxjs8Q9qcl6usaxfj/73Ry/f466vo4kzr7H+xI/8Yl9vq86Kz9rJwa/XVfuPqPXgz5cZaM6tLftOxlcdz8ZG9k9A+vQO/9S0rynd34/9ikmv1ZCmz4ULKw+2XwcPyt+kL58gCy/4FL+Pmrp7z66urw+RUYHvv4fWT23Kms/HQXvPSYlPzu5aTc9q/19P/fycz8L3/E9j5NuvNzIjj4FXm0+NS/fvTkU1jyBXnc/540Dvww1uDwmuL89hTlaP8zYDznP3Ha/LJKHPjfsAjqAK30/gIQNvgCXizyTxlA9UTM5Po0Lsz7nU429S6lqP98mG7/YSl+9QX8lvuXjRj+Fxg85z9x2vyyShz756QI6uA2LOwzwsz25OV8/NzVDPz5otr0qQJi9Xe8iP9eChL0AZHSs8JWAr612fz9VKcY8p1kEOex+fznT7H8/9BHPPZWwpzkjhYQ5J7B+P3xbHjyK+3y5Ru15ufD8fz+jBJK8VaDEPQuuNruKxn4/Wrobv2ckvL5assy+oDAUP46xhb6gpCs/mtEDvzyU7j5rp4s+vAh6PGHXVzuuQnY/JRvZPWXr0DsMU9K8p3d+P7wBJb/nhZw+GwarPhW1HT+d5JG+fOMsv3VT+z5lG/E+fZa8ProXDL6j22A9kf1qPy4F7z3sJj87x2k3Pav9fT+kvHQ/f4fsPaROabwi4Ik+ylJfPtZF4b0lpMo8Pyp4Py4qAr8maLg8jB2+PfoTWz841w85z9x2vyyShz477AI6roJ9P9AUB77APYU8VVIoPR9GJj6DX7Q+HtZ+vYpqaz+/EBm/hUpZvYRJJr45fEg/etEPOc/cdr8tkoc+VOsCOoY5pzsCpbI9Qg5gP7ttQj/UrbW9Zh6ZvTXdIz/ZgoS9POp5sUaM4DCtdn8/Ie+qPAh7AznbroA5u/F/PwFLyD2SQaY5nWOFOdTFfj/o1FQ8ljt7uUdve7l4+n8/bBZJuxmTxD2eKmq7sNB+P/BWGr/ZCr6+Du/KvqaiFT8izo2+/yAsP43ZAL+a++4+2DSRPggZBD2DUPi6eVl1Pxsb2T1/69A7zlLSvKd3fj/dmCO/1wmePuqfqT5NKx8/SLCUvvatLb/LAPU+0J7zPjpHvD5uFRa+LuVwPcmaaj8sBe89WSU/O7tpNz2r/X0/Utl1Pz9C5j1LH2O8RW+CPjzISz6+3eO9eEO6PH8weT+1OgC/DXq3PHgmvT3uOlw/CdoPOc/cdr8skoc+B+wCOqv1fT82r/q94kR3PERz0zw7Tws+Nym2PvnOVr3tUWw/PTAWvwxpUb38Kye+6KJKP0K9DznP3Ha/LJKHPtrqAjohBK87ZFmxPdqKYD8cpUE/WvK0vcH7mb0ayiQ/3YKEvSdMNi61Tz8wrXZ/PzT7Yzx1wwE5LKmCOaf5fz9UHro9gEWjOdBWhznP8H4/CVyjPN2Jd7mCu3659/J/Py+qGjviocQ9TR41u83Qfj+XgBm/9iu/vsneyb6AfhY/aYWSvpppLD+p/v2+TEnvPmN3kD71IC49L3qfu4RadT8ZG9k9jevQO+RS0rynd34/U78iv3vwnj7ex6g+tQkgP2T5lr77WC6/pHLvPszR9T6H/rs+yq0evr2wfj05QGo/IQXvPZ8lPzu5aTc9q/19P46udj+/Q+I9pi5fvJTmeD5JCj4+MIXlvbF+rjwT2nk/+r/9vngLtzxcAr099gNdP1fZDznP3Ha/LJKHPrjrAjqVQX4/n2TrvdIvaDwP61I852ztPcFvtz4S5ze9l+BsP+sGFL+9tku9DdUnvpE1TD+2ww85z9x2vy2Shz6k6gI6Uns/O3KasD2Oi2A/NTFBPxKGtL2tepq961ElP9+ChL266++rh1DAr612fz9Itc071xxdvbMbTrz1mX8/t0yqPb1ZIb6uRIm8H957PxU/Az5WCdw9fmHGuuBkfD8dp+C8c29YPvZuPzyZGXo/J08pv2LlXL7wfmS+p84uPxij/D5QUrw+afE5v7qynD4fu8g+Xj15vgTz3T10aWE/myuavKl+HL8luoo+pEo+P8NUAb9QCeo+xgIEP1YABT8fKjQ/d+CQvqOZET+M2aI+53DWPQEC8D6SsGW9sRNgP95pFT21qKQ+yCt1vS68cT+A+HY/+iDkPXUFYbyM1XM+vVU6Pm6L5b0g/ao8Ogd6P+cI/b4B+rI8Zu6/PSwvXT+F1Q85z9x2vyyShz5d7AI6PVJ+P3+m572gfmQ8vwkWPL7N6j1tf7c+Pug1vYzpbD/1JhS/pl5NvaIsJ75OJUw/ysUPOc/cdr8tkoc+pOoCOlJ7PztymrA9j4tgPzUxQT8ShrS9rXqavetRJT/fgoS9uuvvq4dQwK+tdn8//JftO3IkXb2qxEm8t5l/P0BJrD0VbSG+9huHvDzYez/bPgI+XAzcPTek4robbXw/mIsMvd5ZWD7yRk88tQt6PyhPKb9g5Vy+8H5kvqXOLj+BYf0+a+m8PjNNOb9z0p0+CYLLPiqfd77BGeA98N1gPwbPsrz0+Ry/RluMPuKSPT/EVAG/UwnqPsUCBD9WAAU/O/4zPzqMkb42dhE/2oCjPqfb5T3hMe4+hyN0vRFDYD+2M/08P6qlPunhfL1ClXE/gPh2P/og5D11BWG8jNVzPr1VOj5ui+W9IP2qPDoHej/nCP2+AfqyPGbuvz0sL10/hdUPOc/cdr8skoc+XewCOj1Sfj9/pue9oH5kPL8JFjy+zeo9bX+3Pj7oNb2M6Ww/9SYUv6ZeTb2iLCe+TiVMP8rFDznP3Ha/LZKHPqTqAjpSez87cpqwPY6LYD81MUE/Eoa0va16mr3rUSU/34KEvbrr76uHUMCvrXZ/PxyqHzxNN129/KE+vMuYfz+JYLE9IZ4hvgaSgbzcyHs/2lv/PVsT3D3bjhW76IF8P6YXJL2JSVg++6tNPFT+eT8oTym/W+VcvuZ+ZL6mzi4/C5z+Ptn0vT4eMTi/VMafPhEK0D6QInW+KbrjPRbxXz/eCsy8/M0dv5H4jj52Xjw/xFQBv1IJ6j7GAgQ/VgAFP53XMz8ae5K+ax8RPyeJpD4f+f496EPrPsmXhb0VgmA/ZjC7PN3epj7Ci4W94l9xP4D4dj/6IOQ9dQVhvIzVcz69VTo+bovlvSD9qjw6B3o/5wj9vgH6sjxm7r89LC9dP4XVDznP3Ha/LJKHPl3sAjo9Un4/f6bnvaB+ZDy/CRY8vs3qPW1/tz4+6DW9jOlsP/UmFL+mXk29oiwnvk4lTD/KxQ85z9x2vy2Shz6k6gI6Uns/O3KasD2Oi2A/NTFBPxKGtL2tepq961ElP9+ChL266++rh1DAr612fz/OhVg83k9dvfodL7zKln8/Y3W4PfPgIb58s3O8ybJ7PwM3+D09G9w9fABIuyeefD9rnTC9okJYPl/tOTwi93k/J08pv17lXL7sfmS+ps4uP9EMAD8gL78+ANg2v+Aaoj5GJdU+eYlyvk/65z3k2F4/s3nevEfIHr8O8pE+jfM6P8RUAb9SCeo+xgIEP1cABT9yzTM/i2iTvpeZED/Et6U+6LENPgv+5z4QS5K9FrRgP3waazyZ+ac+MDOOvQwmcT+A+HY/+iDkPXUFYbyM1XM+vVU6Pm6L5b0g/ao8Ogd6P+cI/b4B+rI8Zu6/PSwvXT+F1Q85z9x2vyyShz5d7AI6PVJ+P3+m572gfmQ8vwkWPL7N6j1tf7c+Pug1vYzpbD/1JhS/pl5NvaIsJ75OJUw/ysUPOc/cdr8tkoc+pOoCOlJ7PztymrA9jotgPzUxQT8ShrS9rXqavetRJT/fgoS9uuvvq4dQwK+tdn8/5zKMPEtpXb0Cpx28iJN/P1ZpwD0EKiK+LlJivAmZez8oL/A9aSHcPURagLvqvHw/ySYwvQJCWD4kLRc89fh5PydPKb9g5Vy+7n5kvqfOLj+BxAA/dnTAPtR4Nb/leaQ+USjaPiYgcL4UQ+w9jLldP8r/57x+vB+/o9+UPoGLOT/DVAG/UgnqPsYCBD9WAAU/z+ozP6kjlL4e8Q8/HtumPtkKGz4Q+OQ+z+mdvRTOYD/9GeE7Cs6oPk/vlr058XA/gPh2P/og5D11BWG8jNVzPr1VOj5ui+W9IP2qPDoHej/nCP2+AfqyPGbuvz0sL10/hdUPOc/cdr8skoc+XewCOj1Sfj9/pue9oH5kPL8JFjy+zeo9bX+3Pj7oNb2M6Ww/9SYUv6ZeTb2iLCe+TiVMP8rFDznP3Ha/LZKHPqTqAjpSez87cpqwPY6LYD81MUE/Eoa0va16mr3rUSU/34KEvbrr76uHUMCvrXZ/Pzn0qjymf129gM0MvGSPfz9DEcg9dW4ivqWMUbxLf3s/UnLoPdUk3D1zrJu7kNl8P95PJb0bQVg+73HZO8oBej8mTym/X+Vcvu9+ZL6nzi4/yl8BPzyYwT4hQTS/ppOmPp1y3j44LG6+1wfwPaq5XD9WC+m884wgv09llz6dUzg/w1QBv1EJ6j7GAgQ/VwAFPzYdND9Ap5S+5UcPP3LSpz6pNiY+fnniPoVtp72J1GA/GISIOr1NqT6CsJ69fchwP4D4dj/6IOQ9dQVhvIzVcz69VTo+bovlvSD9qjw6B3o/5wj9vgH6sjxm7r89LC9dP4XVDznP3Ha/LJKHPl3sAjo9Un4/f6bnvaB+ZDy/CRY8vs3qPW1/tz4+6DW9jOlsP/UmFL+mXk29oiwnvk4lTD/KxQ85z9x2vy2Shz6k6gI6Uns/O3KasD2Oi2A/NTFBPxKGtL2tepq961ElP9+ChL266++rh1DAr612fz/nD8Q8UZBdveAK/rtHi38/TFHOPe6kIr4j1UO8lWl7Pw8g4j26Jdw9fP6xuz7wfD+ZYxK9LT1YPvG1gju+Dno/KE8pv13lXL7ofmS+ps4uP23HAT98csI+lGAzv8QaqD51d+E+k9xsvmS/8j0CAFw/mVbivAsfIb/NKZk+RXg3P8RUAb9SCeo+xgIEP1cABT9/WDQ/heOUviG9Dj8Id6g+zLYtPkrS4D4huK296dBgPwp1HLttbKk+D12kvbOzcD+A+HY/+iDkPXUFYbyM1XM+vVU6Pm6L5b0g/ao8Ogd6P+cI/b4B+rI8Zu6/PSwvXT+F1Q85z9x2vyyShz5d7AI6PVJ+P3+m572gfmQ8vwkWPL7N6j1tf7c+Pug1vYzpbD/1JhS/pl5NvaIsJ75OJUw/ysUPOc/cdr8tkoc+pOoCOlJ7PztymrA9jotgPzUxQT8ShrS9rXqavetRJT/fgoS9uuvvq4dQwK+tdn8/PKPSPEuZXb2MBu67l4h/P4nx0T3swyK+I9w7vLNcez9ydN49bCXcPTH0vrse/Xw/ISLzvNE4WD401OE6thx6PydPKb9c5Vy+7X5kvqbOLj/o5AE/NdLCPrgMM78ttqg+FY7iPjFvbL66xvM9NrtbPwkz1Lw5VyG/KsKZPjMrNz/CVAG/UQnqPscCBD9XAAU/eH00P0nflL61gQ4/laWoPiBxMD6hN+A+3PqvvYDOYD+f+zm7rBepPkzzpr1lu3A/gPh2P/og5D11BWG8jNVzPr1VOj5ui+W9IP2qPDoHej/nCP2+AfqyPGbuvz0sL10/hdUPOc/cdr8skoc+XewCOj1Sfj9/pue9oH5kPL8JFjy+zeo9bX+3Pj7oNb2M6Ww/9SYUv6ZeTb2iLCe+TiVMP8rFDznP3Ha/LZKHPqTqAjpSez87cpqwPY6LYD81MUE/Eoa0va16mr3rUSU/34KEvbrr76uHUMCvrXZ/P/Gi0jxPmV29oAbuu5eIfz+d8dE97MMivvbbO7yzXHs/fHTePXUl3D059L67Hv18P0b+urygOlg+kJV9OcYoej8nTym/XuVcvux+ZL6mzi4/oKUBP4GUwj6bbTO/GySoPgs+4T5XDm2+dKfyPcULXD9dvL+8eB8hv0TgmD4UkTc/xFQBv1IJ6j7GAgQ/VwAFP1GDND8cjJS+pq4OP8g9qD4LEy0+U/HgPuAqrb2/0mA/b6SvOcJJqD4xf6W9v+NwP4D4dj/6IOQ9dQVhvIzVcz69VTo+bovlvSD9qjw6B3o/5wj9vgH6sjxm7r89LC9dP4XVDznP3Ha/LJKHPl3sAjo9Un4/f6bnvaB+ZDy/CRY8vs3qPW1/tz4+6DW9jOlsP/UmFL+mXk29oiwnvk4lTD/KxQ85z9x2vy2Shz6k6gI6Uns/O3KasD2Oi2A/NTFBPxKGtL2tepq961ElP9+ChL266++rh1DAr612fz9JD8Q8UJBdvfIK/rtHi38/ZlHOPeukIr6k1UO8lWl7Pxgg4j24Jdw9ff2xuz7wfD95WYW8CUdYPhdKZLmyMHo/KE8pv2TlXL7rfmS+pc4uP4QVAT+3wsE+2G80v2t+pj40tt0+c69uvq2U7z0j4lw/mQKovLt/IL/bp5Y+lZc4P8NUAb9QCeo+xgIEP1YABT+UaTQ/1fmTvm45Dz/OVKc+rjMkPlzi4j6usqW94tZgP3oi2DvRI6c+nUigvXcjcT+A+HY/+iDkPXUFYbyM1XM+vVU6Pm6L5b0g/ao8Ogd6P+cI/b4B+rI8Zu6/PSwvXT+F1Q85z9x2vyyShz5d7AI6PVJ+P3+m572gfmQ8vwkWPL7N6j1tf7c+Pug1vYzpbD/1JhS/pl5NvaIsJ75OJUw/ysUPOc/cdr8tkoc+pOoCOlJ7PztymrA9j4tgPzUxQT8ShrS9rXqavetRJT/fgoS9uuvvq4dQwK+tdn8/SPSqPKt/Xb2MzQy8ZI9/P0cRyD1ybiK+rIxRvEt/ez9Pcug90yTcPVesm7uQ2Xw/l2NAvF1cWD5iGOs5yzN6PyhPKb9h5Vy+7X5kvqbOLj/HWQA/PpvAPmXHNb8gP6Q+Du/YPkzvcL4jdOs9vftdPxI3k7yWnh+/TbuTPjL1OT/EVAG/UgnqPsYCBD9VAAU/nkw0P7Q4k75t5g8/SCmmPl+wFz7MreU+4fqavYDMYD9L6208zfWlPvWSmL3DZXE/gPh2P/og5D11BWG8jNVzPr1VOj5ui+W9IP2qPDoHej/nCP2+AfqyPGbuvz0sL10/hdUPOc/cdr8skoc+XewCOj1Sfj9/pue9oH5kPL8JFjy+zeo9bX+3Pj7oNb2M6Ww/9SYUv6ZeTb2iLCe+TiVMP8rFDznP3Ha/LZKHPqTqAjpSez87cpqwPY6LYD81MUE/Eoa0va16mr3rUSU/34KEvbrr76uHUMCvrXZ/P/AyjDxMaV29+KYdvIiTfz9PacA9BCoivltSYrwJmXs/Ny/wPWkh3D1DWoC76rx8P/ssKbz3c1g+tX0NO2szej8nTym/XuVcvu1+ZL6mzi4/oDn/PuJVvz4pKje/ZtuhPsDQ0z5wcXO+ixznPdAdXz96iYW8zacev9GzkD4DYjs/w1QBv1EJ6j7GAgQ/VgAFP0I2ND9jb5K+x4sQPxD9pD7CCAo+7sjoPv0Dj72GrGA/1SS4PHn/pD5I6I+9A5txP4D4dj/6IOQ9dQVhvIzVcz69VTo+bovlvSD9qjw6B3o/5wj9vgH6sjxm7r89LC9dP4XVDznP3Ha/LJKHPl3sAjo9Un4/f6bnvaB+ZDy/CRY8vs3qPW1/tz4+6DW9jOlsP/UmFL+mXk29oiwnvk4lTD/KxQ85z9x2vy2Shz6k6gI6Uns/O3KasD2Oi2A/NTFBPxKGtL2tepq961ElP9+ChL266++rh1DAr612fz+OhVg8309dveYdL7zKln8/cHW4PfjgIb6Zs3O8yLJ7PwM3+D0+G9w92v9HuyeefD+yW0C8m4VYPtJtlTvhMHo/KE8pv1rlXL7lfmS+ps4uP/vj/T4GIr4+bWw4v9Ojnz60Dc8+RNl1vuUd4z2AIWA/44Z/vGS5Hb/q940+9bA8P8RUAb9RCeo+xgIEP1cABT9YODQ/JKORviAJET/Z76M+yx35Pavo6z7W6IK9fHdgP+u98zw5VqQ+5UWHvZq+cT+A+HY/+iDkPXUFYbyM1XM+vVU6Pm6L5b0g/ao8Ogd6P+cI/b4B+rI8Zu6/PSwvXT+F1Q85z9x2vyyShz5d7AI6PVJ+P3+m572gfmQ8vwkWPL7N6j1tf7c+Pug1vYzpbD/1JhS/pl5NvaIsJ75OJUw/ysUPOc/cdr8tkoc+pOoCOlJ7PztymrA9jotgPzUxQT8ShrS9rXqavetRJT/fgoS9uuvvq4dQwK+tdn8/+6kfPFE3Xb0Moj68y5h/P4hgsT0dniG+BJKBvNzIez/gW/89YBPcPTmPFbvogXw/DZl9vLOKWD5HEu07Iix6PydPKb9a5Vy+635kvqbOLj9P/fw+RRW9PvViOb962J0+hRPLPgkAeL6y5N89EvFgP/yBgLzF+Ry/wc+LPv22PT/DVAG/UAnqPsYCBD9XAAU/ejs0P4cLkb6xYhE/tSqjPlyI4z2nce4+bvFxvf09YD8nrg89tAakPhQXgL3Gz3E/gPh2P/og5D11BWG8jNVzPr1VOj5ui+W9IP2qPDoHej/nCP2+AfqyPGbuvz0sL10/hdUPOc/cdr8skoc+XewCOj1Sfj9/pue9oH5kPL8JFjy+zeo9bX+3Pj7oNb2M6Ww/9SYUv6ZeTb2iLCe+TiVMP8rFDznP3Ha/LZKHPqTqAjpSez87cpqwPY6LYD81MUE/Eoa0va16mr3rUSU/34KEvbrr76uHUMCvrXZ/PxGY7Tt8JF29qcRJvLeZfz8wSaw9F20hvv8bh7w82Hs/3T4CPlkM3D0MpuK6G218PxAoq7wlglg+3rUfPI8kej8mTym/WuVcvu5+ZL6nzi4/dIn8Pj5rvD7L7zm/xMWcPq+7yD5LSXm+ef/dPVBoYT+HHIm85IUcv02eij4HTT4/wlQBv08J6j7HAgQ/WAAFP2g+ND+0upC+FZARP4fDoj7gddY9Xf/vPvSxZb1SFGA/42caPb0dpD4v1na9+c5xP4D4dj/6IOQ9dQVhvIzVcz69VTo+bovlvSD9qjw6B3o/5wj9vgH6sjxm7r89LC9dP4XVDznP3Ha/LJKHPl3sAjo9Un4/f6bnvaB+ZDy/CRY8vs3qPW1/tz4+6DW9jOlsP/UmFL+mXk29oiwnvk4lTD/KxQ85z9x2vy2Shz6k6gI6Uns/O3KasD2Oi2A/NTFBPxKGtL2tepq961ElP9+ChL266++rh1DAr612fz9Itc071xxdvbMbTrz1mX8/t0yqPb1ZIb6uRIm8H957PxU/Az5WCdw9fmHGuuBkfD8dp+C8c29YPvZuPzyZGXo/J08pv2LlXL7wfmS+p84uPxij/D5QUrw+afE5v7qynD4fu8g+Xj15vgTz3T10aWE/myuavKl+HL8luoo+pEo+P8NUAb9QCeo+xgIEP1YABT8fKjQ/d+CQvqOZET+M2aI+53DWPQEC8D6SsGW9sRNgP95pFT21qKQ+yCt1vS68cT+A+HY/+iDkPXUFYbyM1XM+vVU6Pm6L5b0g/ao8Ogd6P+cI/b4B+rI8Zu6/PSwvXT+F1Q85z9x2vyyShz5d7AI6PVJ+P3+m572gfmQ8vwkWPL7N6j1tf7c+Pug1vYzpbD/1JhS/pl5NvaIsJ75OJUw/ysUPOc/cdr8tkoc+pOoCOlJ7PztymrA9jotgPzUxQT8ShrS9rXqavetRJT/fgoS9uuvvq4dQwK+tdn8/SLXNO9ccXb2zG0689Zl/P7dMqj29WSG+rkSJvB/eez8VPwM+VgncPX5hxrrgZHw/KJwXvbJOWD7KbGE83QR6PydPKb9i5Vy+8H5kvqfOLj9OP/0+d6u8Phl9Ob9Ecp0+wbTKPgoOeL7cct89PQdhP9T0t7wl0hy/3vaLPiHFPT/DVAG/UAnqPsYCBD9WAAU/Xv4zP0tzkb6ChRE/9V+jPiNN4T2IvO4+CedvvUc1YD+YsQE9ucSlPhRteb2sknE/gPh2P/og5D11BWG8jNVzPr1VOj5ui+W9IP2qPDoHej/nCP2+AfqyPGbuvz0sL10/hdUPOc/cdr8skoc+XewCOj1Sfj9/pue9oH5kPL8JFjy+zeo9bX+3Pj7oNb2M6Ww/9SYUv6ZeTb2iLCe+TiVMP8rFDznP3Ha/LZKHPqTqAjpSez87cpqwPY6LYD81MUE/Eoa0va16mr3rUSU/34KEvbrr76uHUMCvrXZ/P0i1zTvXHF29sxtOvPWZfz+3TKo9vVkhvq5Eibwf3ns/FT8DPlYJ3D1+Yca64GR8P1ecg72Xj1c+/bXIutG4eT8nTym/YuVcvvB+ZL6nzi4/o7jRPka3zD4Mo0K/eDidPr5+Bj/s5yq+WvvYPeXcUz+jT1C9BNkOvwojrD5fyUE/QJkLv2gd0T7WSe4+wKMQP6PnID+mW5y+JVAmP4dHmT7MLI8+K3W8PvPN773oBGE/5ESrPdhjpT5Ou9S9x9tvP4D4dj/6IOQ9dQVhvIzVcz69VTo+bovlvSD9qjw6B3o/5wj9vgH6sjxm7r89LC9dP4XVDznP3Ha/LJKHPl3sAjo9Un4/f6bnvaB+ZDy/CRY8vs3qPW1/tz4+6DW9jOlsP/UmFL+mXk29oiwnvk4lTD/KxQ85z9x2vy2Shz6k6gI6Uns/O3KasD2Oi2A/NTFBPxKGtL2tepq961ElP9+ChL266++rh1DAr612fz9Itc071xxdvbMbTrz1mX8/t0yqPb1ZIb6uRIm8H957PxU/Az5WCdw9fmHGuuBkfD8zN7K9IW5XPlrrZrxFQHk/J08pv2LlXL7wfmS+p84uPzyR2D4Kd8o+aktBv2V6nT7urAE/oLA2vvku3T0sLFY/G2lAvSNFEb8pWac+9BhBPwbfCr+KDtM+KUbwPqfPDz/KhiU/1HCXvnUPIz8sgpg+WKB6PqWDxj4DMty9RtVhP4cN5T3B4KQ+ZqnTvQQ1bz+A+HY/+iDkPXUFYbyM1XM+vVU6Pm6L5b0g/ao8Ogd6P+cI/b4B+rI8Zu6/PSwvXT+F1Q85z9x2vyyShz5d7AI6PVJ+P3+m572gfmQ8vwkWPL7N6j1tf7c+Pug1vYzpbD/1JhS/pl5NvaIsJ75OJUw/ysUPOc/cdr8tkoc+pOoCOlJ7PztymrA9jotgPzUxQT8ShrS9rXqavetRJT/fgoS9uuvvq4dQwK+tdn8/SLXNO9ccXb2zG0689Zl/P7dMqj29WSG+rkSJvB/eez8VPwM+VgncPX5hxrrgZHw/fjqkvVHiUz7ZOA+7y515PydPKb9i5Vy+8H5kvqfOLj9t9eI+luTGPissP78Pwp0+civ0PjHeSL7+ZOE9l4VZP2cCJ71a0BS/6NefPv8TQD9gnAm/BVrWPm6m8z6PYA4//DYsP/OJkL7Vvx0/7OyXPoV1RT6HeNU+dyO6vY8yYj8lAQI+EaSlPhIswr33z24/gPh2P/og5D11BWG8jNVzPr1VOj5ui+W9IP2qPDoHej/nCP2+AfqyPGbuvz0sL10/hdUPOc/cdr8skoc+XewCOj1Sfj9/pue9oH5kPL8JFjy+zeo9bX+3Pj7oNb2M6Ww/9SYUv6ZeTb2iLCe+TiVMP8rFDznP3Ha/LZKHPqTqAjpSez87cpqwPY6LYD81MUE/Eoa0va16mr3rUSU/34KEvbrr76uHUMCvrXZ/P0i1zTvXHF29sxtOvPWZfz+3TKo9vVkhvq5Eibwf3ns/FT8DPlYJ3D1+Yca64GR8PyqQh72SI04+EJuSPN8kej8nTym/YuVcvvB+ZL6nzi4/vwHuPpnUwj4s1Dy/U9adPsZG4z5chVy+59jiPQ3cXD9dqwm9j10Yv6mblz4ODT8/gP0Hv8B22j5k4Pc+MokMP3ZCMz+hj4m+PkwXPyYOmD6Kfws+zaLlPhndjb0LcGE/CjnxPduHpz55op+9uDBvP4D4dj/6IOQ9dQVhvIzVcz69VTo+bovlvSD9qjw6B3o/5wj9vgH6sjxm7r89LC9dP4XVDznP3Ha/LJKHPl3sAjo9Un4/f6bnvaB+ZDy/CRY8vs3qPW1/tz4+6DW9jOlsP/UmFL+mXk29oiwnvk4lTD/KxQ85z9x2vy2Shz6k6gI6Uns/O3KasD2Oi2A/NTFBPxKGtL2tepq961ElP9+ChL266++rh1DAr612fz9Itc071xxdvbMbTrz1mX8/t0yqPb1ZIb6uRIm8H957PxU/Az5WCdw9fmHGuuBkfD+FeFO9FMVKPuOQ9jzJdno/J08pv2LlXL7wfmS+p84uP4YJ9z4sPr8+vN86v9OnnT4p39Q+SMdsvpiU4T3UZl8/W0vevDoPG788wJA+bEc+P+owBr+r394+4mz8Psx+Cj8p4zg/+ZCEvjA5ET9IOZk+qpu1PS0H8z489ES9jNZfP5f4wD0DCKk+Izl0vWr0bz+A+HY/+iDkPXUFYbyM1XM+vVU6Pm6L5b0g/ao8Ogd6P+cI/b4B+rI8Zu6/PSwvXT+F1Q85z9x2vyyShz5d7AI6PVJ+P3+m572gfmQ8vwkWPL7N6j1tf7c+Pug1vYzpbD/1JhS/pl5NvaIsJ75OJUw/ysUPOc/cdr8tkoc+pOoCOlJ7PztymrA9j4tgPzUxQT8ShrS9rXqavetRJT/fgoS9uuvvq4dQwK+tdn8/SLXNO9ccXb2zG0689Zl/P7dMqj29WSG+rkSJvB/eez8VPwM+VgncPX5hxrrgZHw/w7ItvUJYTD799eM8wYN6PydPKb9i5Vy+8H5kvqfOLj99Kfw+iiG9Pv+6Ob+hfp0+iYDMPqYUdr465989EMBgPxXmvryKhRy/Fc2MPgnbPT/TaAS/lBbjPgZlAD9qegg/r7w6PyJ/hL41LA4/PbybPlBQjT2npfg+K6gdvXDeXj/1tIg9KySpPuX3Sb0NsXA/gPh2P/og5D11BWG8jNVzPr1VOj5ui+W9IP2qPDoHej/nCP2+AfqyPGbuvz0sL10/hdUPOc/cdr8skoc+XewCOj1Sfj9/pue9oH5kPL8JFjy+zeo9bX+3Pj7oNb2M6Ww/9SYUv6ZeTb2iLCe+TiVMP8rFDznP3Ha/LZKHPqTqAjpSez87cZqwPY6LYD81MUE/Eoa0va16mr3rUSU/34KEvbrr76uHUMCvrXZ/P0i1zTvXHF29sxtOvPWZfz+3TKo9vVkhvq5Eibwf3ns/FT8DPlYJ3D1+Yca64GR8P3BjHL1rDFE+dOmzPNRaej8nTym/YuVcvvB+ZL6nzi4/Tj/9PnervD4ZfTm/RHKdPsG0yj4KDni+3HLfPT0HYT/U9Le8JdIcv972iz4hxT0/SNsCv/ek5j4PPgI/EbkGP6wTOD/gF4q+K08PPzNVnz47FKw9Ew71PuGsPL1Ebl8/4qJDPeq4pz4ts1i9ci9xP4D4dj/6IOQ9dQVhvIzVcz69VTo+bovlvSD9qjw6B3o/5wj9vgH6sjxm7r89LC9dP4XVDznP3Ha/LJKHPl3sAjo9Un4/f6bnvaB+ZDy/CRY8vs3qPW1/tz4+6DW9jOlsP/UmFL+mXk29oiwnvk4lTD/KxQ85z9x2vy2Shz6k6gI6U3s/O3KasD2Pi2A/NTFBPxKGtL2tepq961ElP9+ChL266++rh1DAr612fz9Itc071xxdvbMbTrz1mX8/t0yqPb1ZIb6uRIm8H957PxU/Az5WCdw9fmHGuuBkfD8gjhe9BvxVPvOuhTxLIno/J08pv2LlXL7wfmS+p84uP04//T53q7w+GX05v0RynT7BtMo+Cg54vtxy3z09B2E/1PS3vCXSHL/e9os+IcU9P0fBAb+KGuk+IoYDP7x6BT8WHzU/22yPvhvwED85QKI+dZXSPUF38D6/BmK9nwZgP9nmEz2aUKY+K3JwvUZ5cT+A+HY/+iDkPXUFYbyM1XM+vVU6Pm6L5b0g/ao8Ogd6P+cI/b4B+rI8Zu6/PSwvXT+F1Q85z9x2vyyShz5d7AI6PVJ+P3+m572gfmQ8vwkWPL7N6j1tf7c+Pug1vYzpbD/1JhS/pl5NvaIsJ75OJUw/ysUPOc/cdr8tkoc+pOoCOlJ7PztymrA9jotgPzUxQT8ShrS9rXqavetRJT/fgoS9uuvvq4dQwK+tdn8/SLXNO9ccXb2zG0689Zl/P7dMqj29WSG+rkSJvB/eez8VPwM+VgncPX5hxrrgZHw/KJwXvbJOWD7KbGE83QR6PydPKb9i5Vy+8H5kvqfOLj9OP/0+d6u8Phl9Ob9Ecp0+wbTKPgoOeL7cct89PQdhP9T0t7wl0hy/3vaLPiHFPT/DVAG/UAnqPsYCBD9WAAU/Xv4zP0tzkb6ChRE/9V+jPiNN4T2IvO4+CedvvUc1YD+YsQE9ucSlPhRteb2sknE/gPh2P/og5D11BWG8jNVzPr1VOj5ui+W9IP2qPDoHej/nCP2+AfqyPGbuvz0sL10/hdUPOc/cdr8skoc+XewCOj1Sfj9/pue9oH5kPL8JFjy+zeo9bX+3Pj7oNb2M6Ww/9SYUv6ZeTb2iLCe+TiVMP8rFDznP3Ha/LZKHPqTqAjpSez87cpqwPY6LYD81MUE/Eoa0va16mr3rUSU/34KEvbrr76uHUMCvrXZ/P0i1zTvXHF29sxtOvPWZfz+3TKo9vVkhvq5Eibwf3ns/FT8DPlYJ3D1+Yca64GR8PyicF72yTlg+ymxhPN0Eej8nTym/YuVcvvB+ZL6nzi4/Tj/9PnervD4ZfTm/RHKdPsG0yj4KDni+3HLfPT0HYT/U9Le8JdIcv972iz4hxT0/w1QBv1AJ6j7GAgQ/VgAFP17+Mz9Lc5G+goURP/Vfoz4jTeE9iLzuPgnnb71HNWA/mLEBPbnEpT4UbXm9rJJxP4D4dj/6IOQ9dQVhvIzVcz69VTo+bovlvSD9qjw6B3o/5wj9vgH6sjxm7r89LC9dP4XVDznP3Ha/LJKHPl3sAjo9Un4/f6bnvaB+ZDy/CRY8vs3qPW1/tz4+6DW9jOlsP/UmFL+mXk29oiwnvk4lTD/KxQ85z9x2vy2Shz6k6gI6Uns/O3KasD2Pi2A/NTFBPxKGtL2tepq961ElP9+ChL266++rh1DAr612fz89O807FmlZvRmFSrxRnX8/KUeqPdCrHr7N5oa8u/l7P7VDAz6XXNg9rkPEum5xfD86/xy9JRRiPpoCFzyUenk/rrEpv0sfWb7102C+0gYvP6Rxvz600N4+VSQ/v3NarD7Bru0+PfQ9vueIzD1uPFw/I6OevDrpGL+lu0o+KuZGP1dWAb8ZBeo+P/oDPx8JBT+BoSY/PWylvhlaGT8SMKw+JCFWPntz1j5ndcu9v8dgP/MLUzunWaU+08KdvS56cT+A+HY/+iDkPXUFYbyM1XM+vVU6Pm6L5b0g/ao8Ogd6P+cI/b4B+rI8Zu6/PSwvXT+F1Q85z9x2vyyShz5d7AI6PVJ+P3+m572gfmQ8vwkWPL7N6j1tf7c+Pug1vYzpbD/1JhS/pl5NvaIsJ75OJUw/ysUPOc/cdr8tkoc+pOoCOlJ7PztymrA9jotgPzUxQT8ShrS9rXqavetRJT/fgoS9uuvvq4dQwK+tdn8/15zMO3BeUL3uzEG8R6V/PyBCqj14Hxi+tSSBvB87fD+mSgM+rWLPPcmjvrpXj3w/O+AovVTQdz5YXI26dip4PySdKr+u5k++EdVXvguKLz+OfUQ+xAUIP7clOr8ws8c+zi77PuMG7b1QhYc9FHNcP6+c+DyIQA+/wnMvulAGVD9LbwG/YMzpPlXPAz9ONAU/DaUPP2EpyL6EfyA/bhC/Pvf9vj7nRLA+NIkavqMnWT9zO768X3imPmdgz70foHA/gPh2P/og5D11BWG8jNVzPr1VOj5ui+W9IP2qPDoHej/nCP2+AfqyPGbuvz0sL10/hdUPOc/cdr8skoc+XewCOj1Sfj9/pue9oH5kPL8JFjy+zeo9bX+3Pj7oNb2M6Ww/9SYUv6ZeTb2iLCe+TiVMP8rFDznP3Ha/LZKHPqTqAjpSez87cpqwPY6LYD81MUE/Eoa0va16mr3rUSU/34KEvbrr76uHUMCvrXZ/P6/vzDsCqUS9LJs2vA+vfz8pTao94aEPvhh4c7yFi3w/wEoDPvXBwz3SVra6dLR8P7VTNb0HsIc+lYdPvKCQdj8Uwyu/PfNDvtgaTL6EJzA/C4XQPWNfFT8sUy6/f4DcPoVN1z7AwWO90GTWPFy7Zz98owA+Mmv2vmDgJb6ALVo/jL0Bv/Ec6T5WZwM/opsFP/Js8z58V+m+qKUgPyqg1D7a1wM/pbCRPt9mPr6dckk/F7mavF9yrD7KPPS9cA1vP4D4dj/6IOQ9dQVhvIzVcz69VTo+bovlvSD9qjw6B3o/5wj9vgH6sjxm7r89LC9dP4XVDznP3Ha/LJKHPl3sAjo9Un4/f6bnvaB+ZDy/CRY8vs3qPW1/tz4+6DW9jOlsP/UmFL+mXk29oiwnvk4lTD/KxQ85z9x2vy2Shz6k6gI6Uns/O3KasD2Oi2A/NTFBPxKGtL2tepq961ElP9+ChL266++rh1DAr612fz9fhM47ovY4vSiLK7xAuH8/4WuqPbIjB76/yWS8Atd8P9NAAz5vI7g9et+surXXfD/W/Tu9h3SPPtA6rLz0Z3U/Sdwsv/IAOL7QTUC+z7YwP1Q0UrsJ0iI/574bv1IM8z6WvQE/9VF5PSCZG7027Fs/p4wEPgr/zL7X5+G9coJmP4deAr9ms+c+EKcCPzJYBj+AoM0+EW0Cv59ZHD8Ldeg+oqceP3AxeT7Bq1e+IT03P/oPMTyeKLk+HfEEvv5UbD+A+HY/+iDkPXUFYbyM1XM+vVU6Pm6L5b0g/ao8Ogd6P+cI/b4B+rI8Zu6/PSwvXT+F1Q85z9x2vyyShz5d7AI6PVJ+P3+m572gfmQ8vwkWPL7N6j1tf7c+Pug1vYzpbD/1JhS/pl5NvaIsJ75OJUw/ysUPOc/cdr8tkoc+pOoCOlJ7PztymrA9jotgPzUxQT8ShrS9rXqavetRJT/fgoS9uuvvq4dQwK+tdn8/8JXQO7z3L73gHyO86r5/P9CQqj2fmQC+7JVZvMkNfT9XMgM+KDOvPQO/pLqV8Xw/0uswveSWiT5e+ra80UR2PwysLb8P0C6+DCw3voMbMT/weGK+/BAzP3Kj2r4sVQc/rQ8qP3i2ND412Cq+Ifg0PwrACz6MF0a+W195PCCxeD97bgO/A0rlPityAT/DgQc/UTSzPhqCC7/DOhc/s172PlIALj9mc2I+OrRovpFSKT8/hHc9NuXLPjNfB76V22c/gPh2P/og5D11BWG8jNVzPr1VOj5ui+W9IP2qPDoHej/nCP2+AfqyPGbuvz0sL10/hdUPOc/cdr8skoc+XewCOj1Sfj9/pue9oH5kPL8JFjy+zeo9bX+3Pj7oNb2M6Ww/9SYUv6ZeTb2iLCe+TiVMP8rFDznP3Ha/LZKHPqTqAjrCgD87aJqwPY6LYD8mMUE/L4q0vY59mr3gUSU/34KEvdPKK68xPm2vrXZ/P2aZ0Ts1dSy9Sd0fvGzBfz9toqo9HBj8vQg9VbxhIn0/EysDPk62qz0VXqG6Y/t8Py/pA70aqC8+HE6ivAEFfD8x8i2/85QrvozwM747PjE//vSqvm7yNT/xyZW+tLILP01OLz+9A2Q+GfJuvkhKJz+r6Ws+M7gKvUVPQj2Sqng/ag4Fv/KI4T4/Tv8+3y8JPyygqj6vQg6//2cVPzmU+j5u/zE/MupcPvksbr7nGCU/v+D3PeZ74D7PL/+9Xb5hP4r4dj9kIeQ93QVhvMzUcz6pVTo+XIvlvQL9qjw7B3o/Hgn9voHmsjwB7b89Ji9dP5DVDznP3Ha/LJKHPl7sAjozUn4/F6nnvS+BZDy3HRY80dDqPVB/tz6K6jW9hOlsP/wmFL80aE29ly0nvjMlTD/ExQ85z9x2vy2Shz6p6gI6H6hBO1uWsD2Qi2A/ECtBPzArtr1IoZu9kE0lP9mChL1uAwaxAs4SMa12fz+kYtA79/gxvRYwJbxzvX8/1YyqPSYOAr7jQ1y8yAF9P5EzAz6XMbE9HwiluvzrfD8Tovq852L5PE8RgLzqun8/yrkpvwiXVL6XJFu+6MovPzMzYL5uazE/eTXovgsMBD9t5y0/G4QVPhyKEb5lejQ/6mYtPsGp1L0s2mQ9k316P1YqCb+tRdg+RzL5PrOnCz+omLI+WbQJvwloGz+rZvA+nTgsP10Gaj7N2Wy+MSMqPxzYLD6/vPc+iwOovSbTWj+d/HY/DUvkPeouYbzeiHM+KE46PjyE5b2T8Ko8sQd6P5ke/b61Las88V6/PXUsXT/51w85z9x2vyyShz726wI6HU5+P36u6L0bg2U8cPodPCUF7D01dLc+y9A2vTDmbD+eKRS/jzFRvcqOJ753Gkw/TMYPOc/cdr8tkoc+AesCOvj+RTsMjrA9kItgP5oeQT+Edbm9y+6dvcBEJT/cgoS9ADXisUIJ8y+tdn8/asrOO8QbPb2QBDC8BrV/P01uqj1UJAq+C4tqvLC8fD8hPgM+w0K8PTikq7qmy3w/Ir8ovbQVpL395Ti8T/F+P7k4IL+HWJG+5h2RvlQ6Kz8BAlG9DaMjP31QHL828e0+9yoiP6R7Xrv1/GM7thRGP+NdGD4KokK+FJ3iO25seD+08A6/LDvLPt6Z8T53Ew4/6H28PqbDAb+r9SU/rY/dPlK0Ij8ybYA+LIJrvlNoMT8MbD0+yAAJP51jILzH/VI/4AR3P1ie5D0PgWG8wu5yPlE+Oj4BduW9rNaqPKYIej+lSf2+TZObPMk/vj3jJl0/ANoPOc/cdr8skoc+4OsCOslFfj9kveq91IpnPKLfLTxGc+49uF23PkWhOL1m32w/wy4Uv7/YWL2bUii+qwRMP2W9DznP3Ha/LZKHPmPrAjrY3Uk7eIawPZCLYD9LE0E/F2W8vbz8n73HPCU/1oKEvfWVgjGafEwwrXZ/PxtRzjveCUe9WcQ5vBCtfz/yYao9PFgRvhFdd7xje3w/8j8DPoEgxj3Qp7C6bK18P2UjSL1I+/m9G8AevP3DfT9u+he/FxuuvlLRqb4cSSY/6qwHPXQzEz/ZOje/LDfKPsbMQT8gxGa9BSKIPV7FJT+Quie8FxMrvtYDGj11NHw/B+YSv6Eywj7UVOw+ImgPP4cVvz40e/e+HLsuP8GSzT5YcRs//oyIPiKDaL7dkjY/zAY1PrhxFT+Mnlo9i2dKP0UMdz+n5+Q9eMlhvMxkcj7ZLzo+bGnlvX+/qjyFCXo/wm/9voWmjTxOP709wCFdP57YDznP3Ha/LJKHPh3sAjpNPn4/vI/svc5WaTzf+Ts8aZbwPdlJtz51OTq9WdlsP80yFL+lrF+95wApvlvxSz+Pvg85z9x2vy2Shz556wI6yXFLO1KDsD2Si2A/oQ5BP2qXvb0S06C9fzklP9yChL2yFv4xGZHasK12fz8jT847jQ5LvbmqPby5qX8/yV+qPQ1CFL44gXy8/F98Pyc/Az4tHso9uQezusygfD/9tFS98E0LvvFbFLzEQn0/kNgVv4z+tL6Hia++KeQkPyohKz4iDAU/uBdBvxjBuj7rVDw/5lrHvdaJ3T2HWSk/7msovXUbP74Kaps9oId6P6XOE79PH8A+UyHrPlaqDz/Rv7Y++eL0vrD5Mz+qBcY+vZYZPyW+iD6UsmO+5Hk4P90eKD6mbx8/3qi4PSV3Qj9MD3c/HAXlPXjmYbxZLHI+vik6PmVk5b2ktao84gl6PzN//b6G+Yc8tta8PZwfXT8v2A85z9x2vyyShz7P6wI6PTt+P9VM7b1EEWo8vrVBPK9z8T3UQbc+G946veHWbD9QNBS/FXVivdRHKb6B6Us/ur0POc/cdr8tkoc+nOkCOpHATTuvfrA9lYtgP74HQT9qWL+9VQ2ivag0JT/dgoS9ME8HsKis4DCtdn8/DvvNO72+UL2Js0K86aR/P7JXqj0mYxi+iKaBvEY4fD8pQAM+XcPPPSRPurpxjnw/s2FavU4ID75hVxm8fhx9PwtiFb8rd7a+Tr+wviGVJD8Yz0w+uskCP4WJQL8a9bo+EnU3P8FA9L37jQE+N+ksPyry97xFb0u+oLaXPTcPej+x/xO/ba+/Ptzg6j6Qtw8/Ea6nPp1v8b4otjs/y4e6PqmJFz/siIU+HrRXvj6iOz8nIC0+qWkhPzby/j0LSz8/vhN3PzMw5T0FEWK8YdlxPoQgOj4AXeW9oqeqPG4Kej+1lf2+C05/PEw9vD1xHF0//9gPOc/cdr8skoc+E+wCOsA2fj/tX+69nyBrPBsMSjyCsvI9Lza3PjHMO71N02w/NTYUv8iIZr2mrym+Kt5LP3y4DznP3Ha/LZKHPm3rAjq6WFk75mawPZmLYD9g5EA/nyjIvQM4qL2IGyU/1YKEvYKHLDJEflaxrXZ/P19NzDs/a2i9e5pYvGaPfz9JMKo9nogpvgZEkLxih3s/IkcDPllA5z3TING6fDx8P/6ugL1gzxC+3shMvGLlfD+ZXBW/coi2voHNsL55kSQ/FUnAPqlG5T7I6Tq/kUO1PvXEHz/pFzq+VosbPtqcPj+2DG27xjZyvoXBIz5oV3U/8gEUv0+qvz7i3eo+K7gPP3+kxT4ZVee+GZE3Pzp+uj7AqxA/l3+OPj1GV74NZj8/veUwPh4LKj9xfuM9jQA4Pywqdz9PAuY9P+BivJg2cD4t7zk+EDnlvb1dqjxJDXo/EgX+vuSjKzwKObk9uAtdP2/XDznP3Ha/LZKHPqfrAjrRH34/aLvzvX5pcDyX+3M8jOb4PQn8tj4xakC9FMFsP0Y+FL+aCHu9tbYrvuWkSz9fwQ85z9x2vy2Shz6o6QI644NnO25IsD2ki2A/GrdAPwj00r1Xxa+9KvskP9qChL23k9kuOt5ML612fz/bRMo7DNR/vdQmb7zNd38/VwGqPZZuOr6oKJ+8B8Z6Px1RAz6pdf498LfgurXiez9h88W9q+MXvi7hmLwn6Xs/llwVv22Itr6BzbC+fJEkP/naBD+w1MU+R0kuvy7Krz7bTwM/REuAvt1qIz6BLU4/TS86PQ9Vhr7Ex2o+2axvP/EBFL9Lqr8+5N3qPi24Dz/LuPU+cQzevm1LKD/658U+HIv+PmTLqj6gEly+w4dFP6lxSz6ovTg/bwHKPUjgJz/yRXc/FffmPaPRY7x5L24+9qo5PlwP5b14/ak8HhF6P2KJ/r6rK4o7BYS1PXX1XD/T2Q85z9x2vyyShz4u7AI6BgN+P8Ur+r1tw3Y8UHuTPPUiAD47trY+FORFvZOqbD9/QxS/KBOKvS4tLr4SX0s/2MIPOc/cdr8skoc+XeoCOjTiZjvESbA9pItgPyK5QD8xedK9f2+vvaz8JD/bgoS9oyMlMhB1BzGtdn8/YFXKOzYyfr2AlG28hnl/P24Dqj1cQTm+Dh+evB/Uej8EUQM+nNf8Pe2g37o56Xs/FH7lvUjpH770g6e8Eyx7P5hcFb9yiLa+gM2wvnmRJD8FGAQ/fZjGPsWYLr9//a8+DE4EP+E/fr7fgyM++7dNP3UkKj1Eeoa+W9BiPikucD/yARS/Taq/PuXd6j4ruA8/NfH0PmFk376utCc/2FrHPlrN/D44jKw+naxcvpuqRT8TvU4+TkE5P7eSzT3i/CY/t0R3P4fs5j07x2O8g0ZuPiWuOT4oEeW9zQGqPPAQej+Zg/6+ckqTO0iutT199lw/PNcPOc/cdr8tkoc+sOsCOlMEfj8G4/m9pXt2PCNYkjzM8v89Vbm2PmemRb2Vq2w/WEMUv0+Eib1XES6+L2JLP0bJDznP3Ha/LJKHPqrqAjpCO2U7XE2wPaKLYD9+vkA/3zbRvROOrr2OACU/3IKEvYAlVDKF4DoxrXZ/P1l7yjsP+Xq9LXtqvON8fz/CB6o9Vu42vvwSnLyv73o/y1ADPuWl+T0Sed26+fV7P8Nk2L3vQiG+7t6cvHpOez+WXBW/b4i2voPNsL57kSQ/hgcCP5ibyD7wci+/i3ewPqGLBj/wAHm+ibIjPpunTD9Xxgw9VvGGvlRiVD4yA3E/8AEUv0uqvz7j3eo+LbgPP15m6z5cw+G+ydMqPwmSxT4J8wA/9nCoPrqaXL7O6EQ/XX5KPkk+Nz8bV+A9LiQpP3pBdz+g0OY9u6tjvB6Dbj5Itjk+8RXlvRgNqjx8EHo/V3T+vr04qzsqHbY9MPlcP4XYDznP3Ha/LZKHPi7sAjq3B34/fyT5vam/dTwVYI88phn/PV7Btj5pBUW9OK5sP/tCFL8/DYi9FMgtvk9qSz8rwA85z9x2vy2Shz5T6wI6TYdiO1FTsD2fi2A/RMdAPwAnz729HK29yQYlP96ChL06wy4yw2VOsK12fz8AoMo7wo13vfAyZ7xogH8/LAyqPdR2NL5y55m8iwx7P41QAz5MQvY9USXbulMDfD8cqMO9JHghvke6jbyOkns/mFwVv3CItr5+zbC+e5EkP2cR/T535Ms+uOAwv8oosT4pigk/0AByvoHRIz6ELUs/EL/mPGroh760Pkg+FZRxP/EBFL9Nqr8+493qPi24Dz9u1+I+joPjvj2yLT/FjsM+f8gEP4Oaoj5dyly+FJJDPzTRRD5ZJjU/ZqjjPeW5Kz8kPHc/o6LmPVp+Y7zd5m4+6cM5PsUd5b3gH6o8ug96P09b/r4IadI7ndK2PYX9XD+R1w85z9x2vyyShz5K7AI6Pg1+P4vr9734inQ8ZoaKPOu0/T2izrY+c/xDvYOybD9DQhS/L6eFvfNPLb6Zd0s/ZMcPOc/cdr8tkoc+fOsCOoezXju7W7A9nItgP53TQD8BPMy9ARKrvW0PJT/XgoS9Tzg1MpJOVrGtdn8/5ZXKO9jydL3Pr2S8EIN/PyYNqj16lTK+RT+YvEwiez+EUQM+FK3zPUl02bpWDXw/+ZaWvbjdxb2DOlW8lRV+P/YOF7/dMLG+yHmsvq+fJT/lg/U+mxjMPjhXNL8Wja0+wjsJP+bFc77inyQ+QDZLP4s3Az34M4++h2RRPuAAcD/rphK/rerCPtpD7T6BBw8/RbvnPu414L6uuS0/jobBPkXtAz8qq6A+RUVXvgzuRD8iwzc+9nstPykXuz2wDjU/kDR3P89g5j1pPWO8NHRvPgXXOT70KOW9lDqqPKkOej+tN/6+v+0EPB7Ttz2DA10/wdkPOc/cdr8skoc+husCOgQVfj/FLva9WNRyPGOqgzzIuPs9beG2PiWDQr2TuGw/90AUvxZCgr17pSy+ZopLPx+8DznP3Ha/LJKHPrzqAjqtclk7F2ewPZqLYD9P5EA/WDrIvRBEqL0VGyU/4IKEvS9L0LE8/dywrXZ/P4N3yjstNnK9SQ1ivNGFfz/mDKo9t5swvhmBlrzpOHs/NlMDPlj28D3ovte6uBd8P5ntRb3/pDQ9+EE4u1dzfz/Hjhu/fXOivldGoL63Ryg/U2zxPluaxz7LyDi/w6OlPkJBAz+LWX++SGciPjFcTj/JhSU9mPepvlhjeD7nIWk/CuQOv6rJyz77q/M+4AkNP0fZ/j6uUdS+qXYqP0lvvT6J2u4+Mp2oPr8ZRb4xTEw/4IYVPqGQGT/5zVQ9UfJIPz0qdz9OBOY9K+JivA81cD6A7zk+xDjlvYldqjxGDXo/EQb+vnD8Kjz/Mrk9jAtdP0bXDznP3Ha/LJKHPj/sAjqdH34/BsfzveN0cDwXbHQ8UvX4PYf7tj4ddUC95cBsP3Q+FL9bMXu9tLorvlykSz8CuQ85z9x2vyyShz7y6gI67nFSO7Z1sD2Yi2A/9PlAP2bmwr2YiaS9USolP96ChL02+8YwxfFEsK12fz/fo8o7xaptvdizXbxSin8/bhKqPWlTLb4xoJO82V17P/5SAz7IdOw9MorUussofD8fAie99p0aPkCF3zvx13w/CcAgv/U7kL5drZC+cw8rP+fx7D53pcM+Pdc8vxJenj4VI/Y+nSqGvnfNHD4rmlI/DbH+PCVU0b75pos+Pc5ePxsyCr8Zj9Y+PS/7PmZnCj/vehA/zLTAvg6mJD9y3LU+wYvAPjmxuT5IrSa+nkRWPyHbvz0lHf4+WLHRO8fwXD+dHHc/UoblPe9lYrxdM3E+Gw46PlhO5b3eiqo8gwt6PxzD/b5Dkl08Gga7PdEVXT/g2A850Nx2vymShz4s7AI6iC1+P0eN8L1ORm08PCtbPIQ89T2EHrc+ErA9vejLbD8aOhS/Cs1uvU+BKr7hxks/bMcPOc/cdr8skoc+TeoCOu4sSjs8hrA9lotgP6MSQT9Wn7y9JiWgveU7JT/YgoS9AQn9sVCDxjCtdn8/TYXLO5zqZr0cTVe815B/P20kqj0ccii+lGGPvFSTez/FTQM+6MLlPRAsz7q4QXw/zXMgvcMeRz50szo8auV6P9YcJb8HZn++kAeCvmseLT84iew+qvvCPpdbPb/6Up0+uETlPjzzhb7fPQ4+XPlXPy7lAjtfWgC/FkWPPhaYUT994gW/sirgPrjRAD9D2Ac/HjciP2xPqL6DuR0/cXKqPtLJgD7DYtI+IBPzvTZDXj9fz1M9Ag7KPhxQ57z0vGo/vgx3P0zt5D3szmG8tFtyPhgvOj6BaOW9Fb6qPJIJej+8cv2+YpKMPForvT1VIV0/KdoPOc/cdr8skoc+4OsCOrg9fj9/s+y9GHppPJIpPTzDwPA9XUi3PthYOr3e2Gw/GjMUv6EzYL06Dim+3u9LP53GDznP3Ha/LJKHPtzrAjoc/EI7+JOwPZCLYD9bJ0E/9Sy3vaRVnL3JSiU/24KEvfJNpbG6nCcwrXZ/P0vbzDvpbWC9STRRvOuWfz9TPao9csAjvm1Ui7w0xXs/9kQDPpxT3z2jecm6H1l8P8AxG726iVY+2j9aPHUbej8KEii/gmVnvt01br6qVy4/Eij2PhF1vz6YJDu/H3+dPubz0z64aoC+4mb1PWPnXT+HcIu8C5sTvweNjD5G9EQ/LLkCv2QM5z7WDgM/vuIFP+RVLj/lZZi+zB8WP0DrpD5YCh8+Gp/lPlCZor1ZaWA//WsMPazkrj7DIVq9+Q1wPxj/dj/RZOQ9WEhhvHVacz7BSTo+2H/lvffoqjz3B3o/4Cv9vnNnpjwZB789wSpdP97XDznP3Ha/LJKHPtPrAjqRS34/blDpvdoiZjwX5iI8lMXsPUlttz5tYDe9GORsP1ErFL9OiVO9uconvrwTTD/svQ85z9x2vyyShz666wI6s5k/OzqasD2Oi2A/4DBBP/yctL2zipq9rlElP96ChL2c0DUwkNkEr612fz81rc07AjpdveM2TrzamX8/KkyqPdxuIb7JVom8Rd17P0s/Az5GJtw9M33GunlkfD/Hvxe9JFJYPoVIYTyaBHo/C0Upvy08Xb6ez2S++souPzZC/T4CiLw+aY45v3JGnT4rPss+QxJ4viIx4D395GA/ScCwvLI9HL9Dgos+iVY+P0tgAb+s8Ok+9voDP7cHBT+JtTI/TFyTvsVnEj+nJKQ+N231PQFd7D7kOIG9Dm1gPx8r8DyIT6c+KuJ+vd1NcT+5+HY/QiPkPbQHYbxi0XM+UFU6PgyL5b1p/Ko8QQd6PxUK/b5ojbI8l+a/PQcvXT9H1g85z9x2vyyShz4/7AI6BFJ+P9m0573MjGQ8xngWPLbe6j3Sfrc+3fQ1vV7pbD8bJxS/5ZNNvfkxJ763JEw/CMYPOc/cdr8tkoc+E+sCOlJ7PztymrA9jotgPzUxQT8ShrS9rXqavetRJT/fgoS9uuvvq4dQwK+tdn8/SLXNO9ccXb2zG0689Zl/P7dMqj29WSG+rkSJvB/eez8VPwM+VgncPX5hxrrgZHw/KJwXvbJOWD7KbGE83QR6PydPKb9i5Vy+8H5kvqfOLj9OP/0+d6u8Phl9Ob9Ecp0+wbTKPgoOeL7cct89PQdhP9T0t7wl0hy/3vaLPiHFPT/DVAG/UAnqPsYCBD9WAAU/Xv4zP0tzkb6ChRE/9V+jPiNN4T2IvO4+CedvvUc1YD+YsQE9ucSlPhRteb2sknE/gPh2P/og5D11BWG8jNVzPr1VOj5ui+W9IP2qPDoHej/nCP2+AfqyPGbuvz0sL10/hdUPOc/cdr8skoc+XewCOj1Sfj9/pue9oH5kPL8JFjy+zeo9bX+3Pj7oNb2M6Ww/9SYUv6ZeTb2iLCe+TiVMP8rFDznP3Ha/LZKHPqTqAjp4PJi8Iv1LPU3iXj/1OUo/Vc7aPMQNxLsC0Rw/3YKEvS5T0C5aDGAxrXZ/P6KMnrv6oiw8wQZSPDb2fz/TS5U9PGHbPHtF07w0JH8/F5AcPaUxh7yEw5I8p7x/P4V5Dr3N/V+8o/mjPBPFfz/xVR6/8QijvjCKqL7bdSM/sz+YvugMKD9w+gm/kETfPg6Xij68tf08UZZ3vTjUdT8bD8c9obOAPE++Nrx6vX4/GKEav1exsD60o7Y+BqEfPxveg705TB2/GsEpP41h2D5Qvq0+oalFPjlPAz3Dims//dYbPvMZU7y22Ck8jft8P3Pvbz9zOsM8tJFAu7cXsj49HPg9oP36OuYxf7ktHX4/EnUYv/FDNTzi1pU8SpRNP9DWDznP3Ha/LZKHPqzqAjrVc3+/FVEFvSWAgzsnnmc9fKWkPUhk9DrFxye5wit/P3bvF7+zK3E8L6GCvIr2TT+T8Wq7gW9qv7+rzT66keg2Yornu1InTD1vm10/rT5KP2pvyzwIMa27g9AcP9yChL1eK5KugE99Mq12fz/xNaK6B7lSPKidKjz69n8/WeGcPTZbDD3HSsu8lgR/P51yDT3mFbC8GpeTPB6/fz86+ge9ULeYvMVBpjz5wn8/2zEev82Uo76WGqm+kFAjP9C4mL7VFyg/EsQJvz1X3z4cDYk+/UwGPTH+bL3lEXY/mgeLPY1njTzGrDu8uFp/P5jlGr+xwK8+R6u1PtbnHz87NU29M7Qcv4KCKj8euNg+J9ixPoXXUz62pv88TgJqP16LOT5Edzu8tyQhPJq7ez+gemw/1w2LPPMoCbs358M+xaSNPptMODutOVa67gF2P078G789YXg8ABMjPJLvSj9b1w85z9x2vyyShz4u6wI659J/P8GozDwY30m7cTDfPFKBgj4jaGg7XMR4utiKdz9jHRW/CAaJPLEzfrykAVA/VoUlu+c/br9MU7s+B388OH2Lrztchkw97u5fPzZJSj8MwaM8Zihnu17PHD/XgoS9IPYhLnrFt7Ctdn8/K+GZO1/tPzzhw+87B/l/PxqEqD0UFgI93pmivKLzfj+Thus8rIukvJPwcTyI0H8/HmvyvEEzkbxBlYY8JtB/P+XUHb95+qS+14uqvnXwIj+qWpO+qZQnP9owDL8Hc94+9IGJPk8lsTxG5l69eSN2P2AVOT1iY5c8BJc+vGutfz9ikxu/cFatPggtsz56myA/3m+mvUkJHr/zqCg/gynYPgf8sT7pETo+oQsqPV0+az/PZlA+9agpvO6XGTzlnXo/SAhwPwm1ATx04X+6gfKxPhFomD6iiKw6SvHcuSJldD/BDxC/3H15PK+eBzoRlVM/ydYPOc/cdr8skoc+9OsCOiX5fj/PSmY82SfjuuzutD0NY84+a/4+O9JNqLpQR2o/nvr6vkjLRDxfFi+8XBhfP1qlR7phK3S/49iZPmBKlDnyzo484OxMPYtRZD9aVEo/J6JUPJlZjLr2zRw/3YKEvYXkYbBtrumurXZ/P3AhGTw0Rws8DLR/O0b6fz8/UbE9mX3APChWQrwc834/b1DHPFX9dbx7whQ8guJ/P7SR7byeSWK8mlQYPFrbfz97Th2/5PimvsWarL6DZSI/eMSHvuF5Jj8/BhG/Nr3cPjWYjT4DvU677adQvSWrdT+mBAY9veycPM3YP7xizH8/5YccvwXdqT7Xlq8+OZghPyf5E74y2iC/BB8jP/ky2D6l9a0+rVgBPlowcT3WHG4/quZcPiMTILxOJRU88PJ5P5P9dT957Eu7PCXJObXCjT41zYA+k84eulk9GTlexHc/oyYUv5YoWzysaN67i71QPwjXDznP3Ha/LJKHPgDsAjp0Qns/tvmduqTSGznJJEQ++tMPP23I/bmzSq455sZTPwlyzb6XU8A65ehjvJx1aj8nyw85z9x2vyyShz5Z6AI6XB7mPMYtTT0op2g/LFtKP8k1lztjut8678wcP9uChL3J4hGwn/Z1L612fz+Zmxc8W0ibO0reRzl1/H8/z6qwPQVBZDz++g+7KwV/Px1ZyTz97RW8Rd4OO03pfz8+tPW8ERkcvJ/Y6DmJ338/s64cv6lNqb7XAq++V8AhP2sDb74I9CQ/uO8Wv2ba2j6IfJM+7e0WvdLEQ71YqXQ/g+QMPaQtnDy6sD+80Mh/P3mgHb99wqU+UFqrPkO6Ij/6JE++pI4jv0+7Gz9Audk+M7amPuiIlT0Zs489LqhwP3U4Wz7JWyG89sEVPIcKej8Mlns/0x18vLKu+Dppqjw+Ue8jPm3B3bqUvIk5n7J8PzSSEr/Ufy88rrJJvKbYUT+nm/I5ozh2v3sojD4HgRg6RKpvP8pxibyAkgc7IMGzPim4LD+Sxs67Lvq9OzzxPD8zr5e+5jALvJ/qsrwab3Q/M80POc/cdr8tkoc+SugCOuXGEz2ZMU09btxqP/9aSj98zoi7EleQO33MHD/agoS9EIngrNYiFzCtdn8/x6WrOz5eaDopG227pv5/P/JdqD0H/YU7JZH9O6Uffz9fh+o8R8VMu97XoLsH5H8/iP/svFRyprsLyQ28ReF/P1EIHL8DsKu+8XixvlkUIT8HMUi+UyojP/jeHL/sQNk+3AuaPpPwmb3/Wja9kxxzP1WsSD1qtJU8ZCk+vO2hfz90uR6/E4ShPr/4pj673CM/Sc54vgF6Jb9qGRU/m5TbPiJAnj4i8QM9OsCVPa2acj/tk0w+0pwsvNrpGjwa0Ho/9dV9P5SN3LxrjFk7Hu8BPinLBD5GYyG78jakOWXWfT+PXg+//LaTO3a7XLx9DlQ/+fMBO20Cc7/aBaE+m65oOlxRYT8Ditu8cIxYOx+n8j4b/C4/ib04vAmrLDw90To/FDiSvspeVrwlVNq8hTh1P43KDznQ3Ha/K5KHPkjoAjoxwiA9+vVMPeZgaT/eU0o/q4pNvEeN2TvhzBw/34KEvaxljC7mtyWwrXZ/P5pXvbmr/Tu72ADruwv+fz8PMp09Ciy8uzJ2iTxUNH8/nNYLPbl5Pzuvzzq8QdV/P53j4Lx4pqq5EWiJvBPefz+rbRu/lt2tvoy4s757dCA/j60dvmlBIT+jIiK/wT/YPkzCoD6TZOu9uCsnvTIKcT/nDZY9oQ2LPA7gOrwdQn8/vLQfvxyZnT5N7aI+geAkPwr1ib65uia/9AoQP+wv3T4hYJY+mp9OO6jlkD1/CXQ/7Bo0Pk+/P7zX1iI8gvp7P7TZfT+DKxC9vjSOO5+w/j3bAk8+W8WSu8C+cDootno/UnASvxiqeLuslBK8KvdRPwkXjTstlG2/j7G+PnpzkjpKY1s/pB8CvdVZgDtXrAM//kAYP8mwS7xo0xY8vcNNP9aJ6b6RZAG8CNDjvJSyYz9cww85z9x2vyyShz4k6QI6uf0XPfiRTD3pR2U/ukhKP3B+oLz+CgM8FM4cP92ChL0bJfcvVnIcMa12fz+CnKK7XzvPuxUSIryt+n8/xVGUPQukd7w5kcM8rTl/PwH4HT08WA88XRaIvK/Dfz/a99+8L9CZOy3kury41X8/YPMavxSQr74XebW+E/YfP4sO5r3uZR8/+0Amv7P41z76Iqc+onUcvuUeFr3ym24/GjbUPcvsezyLcjW8ZZN+P+t0IL+MhJo+NL+fPjCnJT9sQ5K+m38nvzSdDD81Wd4+kTyQPqWFg7yv/Ic9JgJ1P5JNFT7kZli8TI0rPD86fT/0BX4/vMkfvYKcnTt17PA9tE+JPsD2y7vCJeI6z512P0hrFb+CRii8rJT0OXbaTz/BGN87YV5nvx4a2z5pzY063PVhP2RoCr23hYg7IATwPgZy0z6IYRW837+JO6giaT8hWha/TfWCu1+IyrzSGE8/WdcPOc/cdr8skoc+t+sCOloq/Dz5MEw90bhgP3M+Sj+z2ci8nlAFPJbPHD/bgoS9aCapsMlJAjKtdn8/RFPIu6mJF7xaHTa87fd/P0CHkj0HWL+81YznPN0rfz+K6CE95txkPENOpLwwuX8/HI/3vHTEGzw57tm858d/P9urGr+fi7C+xny2viisHz+2Lpq98scdP1gNKb8uQNg+5a2sPnV3Pb4xXQW9QCdsP65vCz6aaWA8YhEuvKSTfT+34iC/LbmYPvfknT61GCY/kvaWvpXuJ7+Kjgo/aBDfPqwEjD5FL+K83bt+PdKfdT8vBug9caxzvFtvMzzNTn4/YgJ/Py7NHr1fo5w7Vz6hPd2wjj7xD9C7hEzwOv3ZdT8/exe/7vVevIV5KTxXU04/xlINPBXNYr8YbO0+QVFuOmvPbT8HBQW9JjWDO+HOvD6ePi4+Hr58u2mSNTq8Q3w/S5AZv+tBn7t+FLO8Pb9MPxLXDznP3Ha/K5KHPsrqAjpOMKw8RARMPczKXT9xOko/WWnYvLld2ju+0Bw/34KEvYibWy5TBMkxrXZ/P1XyQ7tzhDi8RnImvCz4fz/BOZk9pDzxvML57TwSEH8/XqYUPfEakzyN/6y8obt/P76yE72KF108Bl7ivF62fz/cqxq/o4uwvsh8tr4nrB8/rq1SvbDCHD//cCq/TrDYPgzBsD7gRFK+evb3vONPaj/8VSs+uLRGPMB2JbzWW3w/t+IgvzO5mD785J0+tBgmP3rdmL5yGyi/xLIJP/Rd3z4voIk+lyoGvYblcT2r+HU/HcynPe5Jh7yQeTk8exZ/P9mdfz9n6A69APaMOzO1Kz1J94U+foixuwIwvzrOE3c/19cXv5JFh7yDhjs8sgpOP1q58zsO02W/EoHhPhglhjoWlWw/iArXvI4cVDtPIcM+DlBrPgtkg7sFR3Y6lSV5P6JyIL/cVjG8Pt2TvGhoRz9nNNA4KcF2v/NaiD78GwA6SP0TPJInTD1RZF4/BT9KPwa6y7yVBIA7ptAcP9+ChL2KyDKxdm0PMq12fz++5Rw7dY0/vJjf8LuQ+X8/pxCkPQrIAL0/r9Q8svZ+P7yF/Tw6LJ88mj2fvNfHfz/ouyi9ltR7PJ310LxHq38/YPMavxWQr74XebW+E/YfP1x9cb1+FB0/0wkqv/mG2D4PdLI+hvVMvje8Db2qPmo/QQpGPgOxMTwSHB28syN7P+t0IL+JhJo+Mb+fPjGnJT+ydJe+l/knv5dXCj8zIt8+R9yIPl3H+LyG8Wc9tSJ2P6hLYz3T1pK8V109PBeMfz+Pp38/YwfnvMPhYztFDzI9EKSdPve9o7t0ntI6ZI9zP3kxDb9it3i84SK8usqBVT97dPY6ckNzv1l7nz7fH146l9hsP7cVkrxOGBA71BnCPqb/nj7yLmq79FyXOllXcz/2XBK/jjp2vBDNPLwb+lE/OEAhuc8Edr/Eko0+W1vcOaYEcbshkUw9Z/5hP4BKSj+kbKC8ADybOifPHD/agoS9Lrk6sPPnDTGtdn8/fKj3O3irKbzjQW+7Lvp/P2UTrj03+uq8+UOhPAXrfj+DntQ8X7qSPOM5e7yz138/C6EQvSCJbTywiqm8MsJ/P6ttG7+W3a2+ibizvnx0ID+XLd69gDkfP9SWJr8u99c+YMmwPizxIb6bS0u9gnpsP/E1WD4YqSM8M9gWvFA0ej+8tB+/GpmdPkztoj6B4CQ/9ZeQvudUJ7/pWg0/MBDePs5zij79koS8rKpbPX0Ldj/BMhk98taavK9nPzz0wX8/6RF+P9N+a7yfSeg6BUD5PR3Z8j5dQHK7mygBO2NeYT8ceOm++q4mvAlGhzt20WM/s8gPOc/cdr8tkoc+VOgCOmnqcD+pIgK84VyAOjgbrT4DCqI+OmTaurI0Dzo813I/TnIOv+UUVLy1ZNK7M61UPx+1G7rOr3S/JYaWPtfmpDmUBX+86wFNPeagZj95Vko/RBw4vDHxi7p6zRw/2YKEvQ+mxS8QBzuyrXZ/P9/tHzxrSgK8l6z4Oc36fz91/bE9n8y9vB44NjxN8n4/kizEPIFPcDzvxBu8MeN/PyZduLwE40g8bpZmvPvjfz9RCBy/A7Crvu94sb5YFCE/5XwxvsgyIj/TtR+/6c7YPkSMqz4evM29rYeHvZk6bz9nDV4+QTMfPIy5FLyq4nk/dLkevxWEoT6++KY+utwjP1PthL51Pia/kgoSP1R83D6SZ44+N9n/O1zmTz0SjHU/gU4BPcNvnbyq8j88us5/PxF4dj/O81M7qBDRuUJlij79OyE/qZ2BOp2fYbpZ2EY/DsCyvrbn87qXcGg8Jt1vP2XMDznP3Ha/LZKHPjXoAjpm+HU/R01NO0SByrmb5o0+05CRPscVzTkJ+gC5hW91P9HvD7//eP27Fo1huyixUz/19Zi6kN1yv2HkoT4oIVQ5nkrNvMY2TT1/JWo/91tKP5k0qrpLajy7rswcP9mChL1cVVew+k+SMa12fz8qUf07FYqgu2XCljuQ/H8/QHOtPTO8gbwfnL06OQx/P3X11TxOYSg8KSc3u+3lfz/Mwn+8uV0UPIhh4rvD838/tK4cv6ZNqb7VAq++V8AhP+kNZb5OkSQ/YWYYv6ye2j7JuqM+4lRXvcOEl70xcXE/wPhZPgZQIjzBNRa88Rt6P3igHb97wqU+T1qrPkS6Ij9vpWq+Scwkv0aOFz9Nyto+GJqTPkRJHz33GkU9hJ50P+7/ET1Fn5u89pI/PArGfz9EFGg/OOSMPOr4CrsN7Nc+D08xPwxM3Dt+ONS7zaM4P8hKhr4oc/87OMmgPGT6dj/RzA85z9x2vyyShz5I6AI6hFB6PxH3bDyyvOm6vRdWPowjcz49AP06uTX7ua6teD/lKQ+/DzS5uoodCbvJOVQ/wunsuvq6cL8cLq4+9tXjOOeB+7zqFE0995hqPxNYSj9lKhE8eqiLuw/NHD/XgoS90NmSrwCzCi2tdn8/splPO/m/trrJ6wk8Sf1/PxgPpD1SE+S7/GIFvJ0pfz+uo/s8QtSfO52qgjvG338/aliMvFyfvTvvcGU74vR/P3xOHb/j+Ka+xJqsvoNlIj9U0YO+PykmP7BpEr92atw+8fuaPnvxi7wY9pa9NzhzP/u3TD7Yfyw8/d4avEbOej/lhxy/BN2pPteWrz45mCE/v/BEvo0PI7/IOR0/7kjZPr2lmT7bnJk9OWw6PXkqcz9xGUg9k8OVvL0uPjxdon8//4NcP8YFyTy6SEa7ReEBP2fEJj9ejyQ8Gn0NvOoyQj/GzLe+WjQjPAKVszxA224/IccPOc/cdr8ukoc+degCOvf9fD9oHMk8Dl9GuylzGj7HAFc+GRFFO/3RK7rVSno/ZokQv3LYnjvPsjC7CUpTPziSILvFgG6/Dgi6PhTdPzgWef68iqpMPTqCZz+gTEo/d9aRPHMhq7uWzhw/2IKEvah4WK8eI8ewrXZ/P3uh5Lpn/R87W8M7PGf7fz9xVZo9vCVaO0vfhrxhPH8/6pMRPQx+xLrhACU8MtN/P2sHvLwmzQk6WU81PLbqfz/l1B2/evqkvtWLqr518CI/C5aOvp4oJz+6KQ6/yNHdPvVlkz7QO+w7yNSNvWODdD+R/jA+BzpCPG3DI7ycHXw/YpMbv3BWrT4HLbM+epsgP8cEGr6qHyG/+3giP+1J2D6YT6A+jWzqPTKqLT16HHE/UVqcPWu4iby1Xjo8MjN/P3JoXT8Bz+A8C79du01QAD9WAwQ/KTEUPOFEtLvkUVs/QLwJv9wbBjxSdrE8LrVXP5fHDznQ3Ha/LJKHPlzqAjqaaH4/wD8BPfX5frvlgdo9od9ZPv6egDslpmK64SJ6P5MUFr/IziI8Dzq/u0FfTz89r0W7lX1sv3cJxD4r7YM3vBDbvCA1TD3O7mI/+z9KP7Ebxjy0tr27O9AcP9qChL2y2sgv7WRNMa12fz/o8pi7P63TO2l+VzxA+H8/EPWUPVRKcDzvLbm8kTp/PzjKHD3cDQ68iaVzPEHGfz+GPfe86/XEuyf1iTyq138/2zEev8yUo76UGqm+kFAjP2D+lL4ewCc//m0Lv0fC3j7G840+uHm5PHm9g70IWHU/kC0JPmJGYjzJly68OKd9P5flGr+ywK8+R6u1PtfnHz9lKdm9bh0fv/rLJj9699c+MDGnPjOgHj6v5hs93H5uP2qN7D1j0XG8kewyPD8+fj9L8Gc/23PhPLdhXrvFPdg+6p+YPmAMqDssD9u6fFt0P5wnHL8lWg08vkmoPFPHSj8P1w85z9x2vy6Shz4n6wI6I4B/P4CoDT18uou75jNUPUv5Sj6YhYQ7eDdZuhbrej/IUhu/YGdWPKlUMLwpc0s/H1pgu8AFa7+C+co+/U72Nng8mLwi/Us9TeJeP/U5Sj9Vzto8xA3EuwLRHD/dgoS9LlPQLloMYDGtdn8/ooyeu/qiLDzBBlI8NvZ/P9NLlT08Yds8e0XTvDQkfz8XkBw9pTGHvITDkjynvH8/hXkOvc39X7yj+aM8E8V/P/FVHr/xCKO+MIqovtt1Iz+zP5i+6AwoP3D6Cb+QRN8+DpeKPry1/TxRlne9ONR1PxsPxz2hs4A8T742vHq9fj8YoRq/V7GwPrSjtj4GoR8/G96DvTlMHb8awSk/jWHYPlC+rT6hqUU+OU8DPcOKaz/91hs+8xlTvLbYKTyN+3w/c+9vP3M6wzy0kUC7txeyPj0c+D2g/fo65jF/uS0dfj8SdRi/8UM1POLWlTxKlE0/0NYPOc/cdr8tkoc+rOoCOtVzf78VUQW9JYCDOyeeZz18paQ9SGT0OsXHJ7nCK38/du8Xv7MrcTwvoYK8ivZNP5PxaruBb2q/v6vNPrqR6DbkX5o8zrNnPS8iVD/kpFE/GrUAvVkXFj0hZhI/4YKEvb4BA7IA3yWyrXZ/P7rc2T1GWK49OeeLvVUCfT8Pcis+E6uOPiAjzTzHAnI/EuaIvSsWP74l2hy7but6P0i2/r1L7zy+pp3lPKB6eT8qBB6/E0WkvpHQqb5UISM/7KA3vnCUNT+ulce+iiwPP8JiIz+mzdk9mujtvN0MQz8lBe89DCQ/u9BpN72r/X0/F6Eav1axsD60o7Y+B6EfP9O3KTvw5Sq/HsIFP3bJBz9PmzA//gyRPqrPdr5U/h4/WzJDPuhFIL3M0To9pdV6P9JyYj9v10q9GBTIO4Bv7T7iGC07OSqgum6f1ba5/38/iRb6vuJKvjxedD89q/teP4O7DznP3Ha/LZKHPkLsAjqeunu/KoEsPa0nqrt2ITU+XF3WPlwaGryqwY07kHdoPzqS176fBrY8wZw2vKkdaD8M2A85z9x2vy2Shz5T7AI6ypJ/PHDMZz0yaT0/orhRPwAI1bzxbPg86nMSP9qChL0KTigyaE7fsa12fz/j+609ZgaEPf3TWr0kLH4/JFYbPrVrWT5zO8g8GA13P7WSQb0vSxG+ohOAu3gefT8otNe9eAEQvim1nTwu+Hs/AiUdv9WUp77BO62+oToiP9yhOL7V5TQ/qGrOvoiGDT/LgSQ/QOy9PeLvlLwdpkI/HwXvPR8kP7vNaTe9q/19PyIVG7+3GK8+2/20PvgYID9KmsO8ATAsv5b6Az9rwwc/HzAzP46xgj7K/Va+dxMiP1syQz7lRSC9zNE6PaXVej9m90k/s2kQvQVyjjtPCx0/B6sfPyethLwE41c8qghIP8avE7+fAro8FZAQu9oFUT+AFT85z6Fvv2sjtD5OLP45B9R/vwMkFD1SH5K76RFxu+y9Jj/8HzK8ru0bPAk3Qj+6lQG/UYNmPPE2XLxEuVw/1MAPOc/cdr8tkoc++ekCOsRwDDxs8Wc9dmY1P4zWUT8BC2q81HaIPOWIEj/cgoS9CXVKsvDKU7Ctdn8/KPaFPQ4UsDwq1Pq8rUV/P1VnDz5+8po9wrNAPN+3fD99+Pu8FZ1MveE5xrkgj38/th23vVkiSr3dXP47Wqd+P2iZG7/SQK2+txazvrKhID+ggTC+iYMzP62m275+7go/vAgnP2Onbz0J3CU8C2dBPyIF7z2RJD+7u2k3vav9fT8UDxy/a5erPotfsT5WGyE/2s6dvR88L78xTPo+2gcJPyyWNz93tUQ+5dYPvgixJz9YMkM+5UUgvbrROj2l1Xo/swZgPwtoprz2IyQ7/Y33PgXIOD82EBm8uJsjPJUkMT81rS2/UW8ROlHB1btyETw/6VCGOYp5Xr9LTv0+qvXrOYq6aj+EH6K8UeofOw8VzD71LVs/mT8GvOcZWzx4NgQ/ev/wvuUjgrqUwAm987NhP9jFDznP3Ha/LZKHPj3pAjq8tJo5GgNoPYfpRz+B41E/NuMAuj1NFjrekRI/24KEvRB/b7AQveCurXZ/P9Xgqj2TeLi8DMSQts4Kfz9LxSM+FUuIvYkUvbk7IXw/kY5LvfMoNz1RHC26X21/P+TF3b0uRjQ98f0BvKo8fj+Wphq/Gp6wvtaPtr60ph8/NhwdvsyXMT+W+uu+WSIIP80HKj/1ch48qStYPXziPj8dBe89uCQ/u8BpN72r/X0/4jEdv35kpz7cCa0+8EciP+wRAr69rzK/7zDjPtopDD+wfDo/4B3uPcYsbb1BMyw/VzJDPuZFIL260To9pdV6P56afT/gQD26/Ky6OE/FCz5JT+0+NF/Qucg+pDlk12I/LMgjvwMOKrmv+Rw5mMBEP4D6mznbiFG/XBMTP2g73jnsEy0/wLLUuYXNUTh0oDw/Ns5ZPxG827kTvEs6JYYGP4ua5L48h6M96BYHvm2jYT9ivg85z9x2vy6Shz4z6AI6lBvcuxX4Zz385l8/iNtRP7BjNzzC21W8ZIwSP+CChL3OCREzdp/AMa12fz+84+094UdNva/aJj2fun0/hIpBPgUlJr7jAbE7Q+13P/I7qL2pA9s9A4hjvAejfT++og++X3XTPZjr/rwO9ns/F6Eav1axsL6zo7a+CaEfP1ZB+71Zfy8/zxr7vncdBj86iSw/V0w8vZDH1z2j0To/GwXvPXgkP7vCaTe9q/19P0wRHr9/EqQ+XJypPuguIz80Txq+V3M0vxPa0z4BWw4/13w6P5ZXcD35cY07jrsuP1oyQz7jRSC9u9E6PaXVej9n0H8/jdWUPBfPErsp5Ai9AFm6PjCCWztxYai6unBuPzVGy7643L+7MoiEO8nzaj9VmH85Ad9hv7T78D7YjO85a4woPw+1NjwcOLS6y6lAP02GMj/Ei/k7pq7tu9x1Nz833gW/m+DEPYGTIb36lFg/U8IPOc/cdr8skoc+3uoCOoaOQ7xe42c9iGdvP27KUT8596I8xwq+vFeAEj/dgoS9nU34shJbuDGtdn8/0UwHPqbwib3xh5M9Gn98PxNCTT6YUmW+U2U+PFMldD+OMci9HIQWPuLLybyk5ns/7C0fvghmED5cmkW9S/55PxihGr9XsbC+s6O2vgihHz+I3a69cpYtPxYBA7+ORwU/QO8tP/ppzL0mKiQ+SoI1PywF7z2JIz+7yWk3vav9fT9oZB6/stCiPiFQqD7PhCM/IAwmvjY/Nb/x2cs+QG8PPysxNj8uV6s8s+EzPUZoMz9VMkM+40UgvbrROj2l1Xo/EC19v1JEAb2YAn87cCQUPmq0Vz6h3H47TiteuvRAej80yaC+QL85vLqjvjsFB3M/R1QlOULZc7+M3ps+GE8BOofLMD/SBrc8mIg0u74OOT9laBI/yP86PH9gAry7+FE/GkMUv4P41zxK3cY785RQP1/IDznP3Ha/LJKHPivrAjqlP3i8/s9nPX1CcT8Qu1E/POrOPBFL8bybdRI/2YKEvYHPprIzzzyyrXZ/P9NLAj5iMp69o06vPZ8yfD8rzkQ+2BSEvsFQIzzmYHI/73O8vWu6LT6ppdm8Nhh7P0chGb5u+iY+GotcvU9GeT8WoRq/VbGwvrSjtr4IoR8/VKBDvUspLD/6tQW/O6wFP3k2Lj8S9xS+PP1XPoW8Lz8nBe89iSQ/u85pN72r/X0/ZmQev7HQoj4iUKg+0YQjPw9bLb7anzW/4K/HPmXhDz/Z3C4/VvJCu4Zqhj0hNzo/WTJDPulFIL2o0To9pdV6P/S5fL/cuCG9woSfO0oSHj5UimU+FGeqO+ssn7pMe3k/QeipvtnMc7yAce87q3RxP5zNDznP3Ha/LJKHPlXoAjqWcTY/Za/2PAVTc7tnajM/T/r/PkfATzy4SvC7Xq1dP5qmHL9ZpFU8sB2DPDJoSj+Pvw85z9x2vy6Shz7g6wI65umHvMHFZz1kE2s/ALNRP1mX4jxrHgS9+m8SP9mChL2rteMyagIBMq12fz9es+c9kvmnvbcSrz23inw/o6c0Pi5ai772Ezw7rihyP21Znb0UETg+IHi2vAf/ej/olAm+EeUxPrXsUb20Z3k/F6Eav1exsL6zo7a+B6EfPzy/kbwcVSs/gzAGv0K8Bj+l0S0/yQo2vuCQfz6Pyio/IgXvPagkP7vHaTe9q/19P2dkHr+w0KI+I1CoPtCEIz9HBTO+uK41v+fJxj43rw8/llMnPxf0gbyejpg9aMNAP1kyQz7jRSC9wtE6PaXVej9Hn3y/zZYpvZRHpzv5MiA+WqmaPuAJ5Dsb9RG7oQh0P/e3sb7hP468aO0UPOsHcD9P0w85z9x2vyuShz546gI6UahGP7vsGT0P1Je7siwhP+xJsz4GtiA8RAJ5u7bGbz8z4xi/GnXoPHa8KD3I7kw/6c0POdDcdr8pkoc+zuoCOhmBi7x7wmc9itBdP2awUT+Sleg8LJ0HvSluEj/dgoS91SD6ssiyHTKtdn8/U5LFPd+0q72zNqI95hZ9P7kRIz6XD42+jUa9uwqwcj+kbXK9kio7PgkagbzTMns/WS/vvRQKNj6VnTm9a995PxmhGr9WsbC+s6O2vgehHz9koJC5YPMqPwHdBb9ungc/UF0tP6YjSL7ILYs+0LsnPyAF7z0UJD+7wmk3vav9fT9pZB6/stCiPiJQqD7PhCM/Kkk4vteNNb9yz8c+PhMPP0QqIj/0Za68r52dPYwHRT9bMkM+6UUgvbDROj2l1Xo/C/d7v6mGIr2iT6A7PWcwPn2swD4WWgI8dNtUu+0rbT8U4MS+4SihvM73JjzkP2w/qsAPOc/cdr8ukoc+A+oCOrWtWz9NaTI9Avuvu1b2Aj+jTtM9V2xiOwPI3rnVoX4/AEoGv7oJFD2vsIw98wpZP37CDznP3Ha/LJKHPonsAjr6wX68M81nPV4oSD/puFE/yVjUPJ6g97wbdBI/34KEvV45UTPhBJ0yrXZ/P6tQoT3+Kpq9PrmNPc7bfT8BgRM+CLh8vs/hEbyPUHU/lT4rvaafJz48K0y8vkx8P2UszL3CTiM+iI4fvdI7ez/gqxq/k4uwvrZ8tr4trB8//Aa3uy9GKz+YVQW/arkHP2Q3Lj9g6UG+DFKIPh/lJz8iBe894SM/u8hpN72r/X0/T1kev9f7oj6tfKg+WHkjP6JRPL68NDW/MRfLPp0HDj8FpCE/IcaTvOahlz3njUU/VjJDPulFIL3D0To9pdV6P6O3f7+DKxa9OSCUO1TI7Tx/gRg/AvknPEwvALzulk0/rPvxvicHeLyTpVQ8xYthP6rADznP3Ha/LZKHPtrpAjowkk8/S90XPfTLlbtShxU/eJ7VPhnsMTzOH8q7t6FoP/6B/76hIBc92yEIPdl6XT/EQh85qL50v3sllj7/ywE6DC4bvIzuZz09TTY/utNRP2dOgTxLypa81oYSP+CChL3+m0KzEON5L612fz9AlX89SUX8vLxQXj1QAH8/z0ELPkRG370SruY7MRN8P8iq5bxMh489Z6ykvMI3fz+/Y7G9XuiGPYb5/7yhWn4/JO0avxGmr77Jj7W+pO8fP0pnSL2fji0/OU4Bv64mCD+53jI/BZgOvsovWz47FCs/JQXvPVIkP7vQaTe9q/19P7IVHr+QAaQ+3YqpPnIzIz+zoji+YCk0v6pi1T7o3gs/yBIkP6mN9Dut0Vo9CQZEP1gyQz7rRSC9tNE6PaXVej8WLWY/HiqwPCbDLbux0t8+97hdP1BoFzwnMYO8acH/Prwh4b4Z/iC72hEEvOLpZT85xg85z9x2vy2Shz746QI60plRPyRrrzz/Bi27neASP1EuNT82ICk87ywnvMfRND8spyS/wdJ6OpGH+DuhA0Q/Pk5mOVbUZ79yLNk+7+H1Of7EUbsrAGg99dc7P6fhUT8Xwq47xsrLu7SQEj/ZgoS9f7u+MQxys7Ctdn8/Zx6DPcvTkzzQVg89oEZ/P6J6ED4LNTM9RgatPDsifT8gJPa81oUEvfPUvrxJrn8/Bri1vfVKEr1fHpG8M8l+P7hbG7+uHa6+uvqzvvFhID8CA9a9ogcxP5dU775lbAo/h9g3Pz2Pg70McQo+afotPyMF7z0yJD+7wGk3vav9fT9ioR2/Ar+lPrxWqz40uyI/Ybsqvlh+Mr9KeeQ+1SAJP07JJz8YhlA9dQmGPBHdQD9eMkM+/EUgvbPROj2k1Xo/WAs0P1B6mDueZha6Nfw1P750ZD9PDHw7FeYAvNP85j7AWs6+FTQEPQhW7L0tRWg/2MEPOdDcdr8pkoc+jeYCOsT9cD/3CAs8VCSJuoqtrD77iyc/HJdGO9DvOLuwjUE/1C8uv1KRuLq33jI7/pk7Pz1SlTlZzVW/y8wMP1LC4jn7izM7swBoPRKFVD8k4lE/ZZSVu15urjsIkRI/2YKEvQ3Sm7HwGV2wrXZ/P7CNlz3K6EQ9uBfuO5n+fj/Vyxg+EacRPjqswzw7bXo/2Y0fvXZ2x72X9Y68bIx+P3Zlx73Onsq9CM+xuoKFfT/k6Bu/CyKsvqnusb7f8yA/s70QvtnHMz++A9q+o4ANP3VwOj98QdE7pJp2Pfu+Lj8rBe89zyM/u7ppN72r/X0/kgkdv5b7pz7Vpa0+RR4iP/tPEL4RczC/qZj0PkayBj8ZrCs/7cvXPem+C71Exzs/WDJDPupFIL2u0To9pdV6Pzz6KT9bE4S780YCOipsPz9+/Uo/Dspqu315jzso+hs/oML5vnXnyT14lsm9UJxcP6jCDznP3Ha/LJKHPufoAjrmwn8//TTyu6PobjovLi49iczdPjKc6rqB01s6R7tmP+PBB7+CH/g6B1CdussJWT+cJZM5riRXv/W9Cj++LOQ53loIPHLzZz2uIWk/VddRPyE6Y7xMfYQ8WYkSP9mChL1U4Jgxjpmpsa12fz8X1609z82JPfh9m7yJcn4/JbcfPgsAVT6788082xx3PxYnRr27GRC+zMxGvHghfT+r/tm9QTMQvsxXMzze9ns/doAcv2b4qb4Zs6++i5AhP0XtIL7N5zQ/m2HPvu72Dj+N+Dg/KWpXPZzeOjxLcTA/GQXvPfUjP7u+aTe9q/19P01iHL9GZ6o+lyWwPl5xIT9Xidi9gm8uv1vWAD8mVAU/MKouP+sSJT4yfrq9oQ41P1cyQz7pRSC9sdE6PaXVej9Kyi0/kLpuvBR66zrg7js/75AnP49PF7yauwE8u4NBP+UVDr/j50U98ZvSvBN9VD/OxQ85z9x2vy2Shz6Z6QI6i7F+v3+rtTzfMTO7AIPJPf9ajT5p0Ge7J2+DOl4Mdj8v0qK+qmrgO0mairues3I/v4BPOVuTbL/JocM+SOf6OTW5VTxR3Wc9ewNyP4zFUT9aHbK8G7XPPO18Ej/jgoS97y0hMSnVeLGtdn8/zkzBPeSuoD2T0Si9ZNh9P1fqJD4hun4+6RnQPCdqdD/nYGe9bHYrvlwp/Lue9ns/pAfqvfV0Kr5FMqE8Ra16P5gSHb/Q2ae++oKtvpsnIj9z+ym+tn01P8s3yb5exA8/hE0zP/SZpz2EfIW8f3c1PyYF7z1TJD+7zWk3vav9fT+uvBu/2MGsPqaTsj4qxiA/yNKIvRPALL/W4wQ/FzIFP3JYMD/UfVg+bgIXvlhyLT9bMkM+9UUgvbHROj2l1Xo/VPwyP6XCy7wG/Eg7/+o2PweOCT8x2kS8J376O6HfVz8nkRm/mGwEvKKmDbxmzUw/0dYPOc/cdr8ukoc+geoCOqBIfL9GFgw9xS2Ku4c6Kj6v5jg+y4yDu977Pzo0yns/kAqmvsFLRTzLiLK7BiRyP+vMDznP3Ha/LZKHPkLoAjqefoU82sdnPYL4bj+3tFE/343evOTDAT0scRI/4YKEvTm29bLwtpKxrXZ/P54Jzz2j36o9tX9nvehgfT9Sdig+m7+JPj1lzjwT2nI/B+x+vZLsOL7a+pe7mUh7PyZ29b2WOje+93HLPGXpeT8wjR2/vAumvu+lq75WpiI//CIwvjOwNT+34ca+Gt4PP7HGKz/pSMg9WCHdvBgHPD8jBe89XyQ/u9RpN72r/X0/Ui4bv1K/rj6YobQ+BDMgP1VrAr0Iqyu/szQGP/IeBj9G2jA/v65/PlbVR76NXSY/VjJDPuRFIL2s0To9pdV6P97IPj+WIw69/zOMOyF2Kj9KttU+Yuw+vG+esDvtm2g/ih4cv2PlHDvOdVI7LeJKP47TDznQ3Ha/KpKHPuDqAjrfyXy/K5IqPY0/qLsY4Bs+TWeHPrgT1rtZw+s6JOF2P49Grb4boYA8pbUDvAPacD+Xzg85z9x2vyuShz5r6AI6i/qUPEy5Zz3ycGU/NKlRP0hn+Lxd1hA9ImkSP9+ChL34nT8zkBJfsa12fz8JE9c9gyKuPUHChb2+GX0/8aEqPozjjT5dOs08RClyP2Nwhr2YKj6+oF1Au9b7ej9ZSfy99x08vuUJ4Dyij3k/3uEdv8XIpL6FWKq+4f0iP1+KNb4JpDU/XRTHvlBwDz/YSCU/uh7XPXAh77xBfUE/JwXvPfojP7u9aTe9q/19Px/KGr9pIbA+Ig+2Pm/LHz+A9u+7RhYrvwITBj+gOQc/m78wP61KjD4FWGm+5CghP1oyQz7tRSC9udE6PaXVej+n7FQ/9Z43vVketTsWpw0/Azg+PpeazbvNGMI69ol7P555Db+QEI88VJLxPPMsVT9Gyw850Nx2vyuShz7H6wI6L0d8vxitMz06OrG7//wnPvbirT7oygi8ZqlFO+zFcD+gYbm+MpudPGJFJbzHkG4/bsgPOdDcdr8skoc+9uoCOuRfmjzOs2c9LyJUP+SkUT8atQC9WRcWPSFmEj/hgoS9vgEDsgDfJbKtdn8/utzZPUZYrj0554u9VQJ9Pw9yKz4Tq44+ICPNPMcCcj8S5oi9KxY/viXaHLtu63o/SLb+vUvvPL6mneU8oHp5PyoEHr8TRaS+kdCpvlQhIz+27Dq+GnM1P1O1yL7PrQ4/R0QiP5ot2z2SYey8xvVDPyMF7z3dIz+7wGk3vav9fT8XoRq/VrGwPrSjtj4HoR8/07cpO/DlKr8ewgU/dskHP0+bMD/+DJE+qs92vlT+Hj9bMkM+6EUgvczROj2l1Xo/0nJiP2/XSr0YFMg7gG/tPuIYLTs5KqC6bp/Vtrn/fz+JFvq+4kq+PF50Pz2r+14/g7sPOc/cdr8tkoc+QuwCOp66e78qgSw9rSequ3YhNT5cXdY+XBoavKrBjTuQd2g/OpLXvp8GtjzBnDa8qR1oPwzYDznP3Ha/LZKHPlPsAjrMX5o8gBuYPZINXj/B+mQ/IHoVvXZrAT1lnOM+3YKEvVTd4LHzuIGxrXZ/P/6qgD0QkoE91pZWvZ+gfj8W+wI+VwlWPiWfJz0t+Xc/5NLAvEkQEL4V2Hi8Nlp9PzEZar6RQRC+7nZavOCSdj8qBB6/EkWkvpHQqb5UISM/4KA3vnKUNT+zlce+hywPP8FiIz+Uzdk9I+jtvN4MQz8fBe89aiQ/u7lpN72r/X0/F6Eav1axsD60o7Y+B6EfP8e4KTvv5Sq/IMIFP3TJBz9OmzA//gyRPrTPdr5U/h4/WTJDPuhFIL270To9pdV6P9kuXD/NC0C9LW69OwsJAj8hIC07R3mbum8s2ba6/38/38cFv4YExzzztjQ9u+FZP3rDDznP3Ha/MJKHPsHrAjryQng/bulUvfsC0jtDDHQ+NoAWP9bEhLzW10A8UAZPP8j+ub7OXa077+9xvCN6bj+RwA85z9x2vy6Shz7p6QI6sEhjPGpfmD3E2U8/HxplP00C3Ly+fL48lrvjPuiChL1aZKyybd9Rsa12fz8sgTo9h3NHPaIRE73aQ38//qfsPXXjIj7k+gg9b9t6Pw0FCbxbkNu9POhYvDR+fj+Z+Te+S57cvY/nBryhT3o/lR8dvympp769UK2+CDUiP66NM77u6zQ/cIDOvjzfDT/n4CQ/M7SPPZiiYDo0AkM/KAXvPUYkP7u7aTe9q/19P4UoG7/w064+3ba0PgMtID9tveW8XUcpv3f8DD83MwI/d6s1P9NeZD4ylTK+FyolP1cyQz7lRSC9rNE6PaXVej8+Fz8/n+XuvNCkazv2Lyo/8KPuPmi0K7wjIrs7t3hiP6YU+L7OTRu8DeAQvNjqXz/tI0A54W5vv4YxtT798v05WX1rP7PND71q2I07d/zHPh1aPj/evWW8cWN8PHMYKz+A2s2++tdTOSVyTLwhYGo/K8APOc/cdr8tkoc+6ukCOmKQ5DvenJg9oFpNP3I1ZT+4K128gn4/PJDY4z7mgoS9jq0NtBJMDTOtdn8/7pYVPeLhijxMs6C8PL5/P0ZZ5T2PHW09pAV1PMXtfT+Yff+6rwAfvWrdqLubzX8/YhckvjsKIL2cWiu7Kn58PyeSG7/bWq2+lzGzvjSaID9UIiG+PogzP50S3L6z5ws/TpUnP2HYnzzV9zM9EyJBPyEF7z0YJD+7xGk3vav9fT8HPxy/h+iqPv6qsD7oTCE/nmawvU1AKL9ZSBI/Srv3PpGtOj+Gndo9pvZCvZWaLD9dMkM+80UgvbXROj2k1Xo/YVJYP5k3h7zVYQU7xNQIP4EJGz8Vfum7/Qq0O4OzSz9TJyC/wCOoulynkrubtkc/2fyGOf4cXr9akv4+QJPrOXoSUz/w0nO8NoPwOj7PED+DiFM/19MBvN1xOzxsJBA/DznDvkKJpzo1kK08BJlsP8fIDznP3Ha/LJKHPnPrAjpnLomymLaYPa+TVz8qP2U/AACAsAAAgDBq4OM+3YKEvQAAgKgAAIAnrXZ/P3r3XD2v35G8sLEcOiaWfz+0zwU+E2BZvRFDULrfcH0/EPikvCavET1Oq1e6N8l/PxrIRb6UWhE9dOglu6wDez8WoRq/VrGwvrejtr4HoR8/zaoAvvGfMT8Nreu+bRMKP4xhKj82Bxy9jgDFPbg4PT8jBe89tyM/u8tpN72r/X0/O3Idv+Zxpj5pD6w+d4oiPzR6Dr7xDSq/Jv8NP+J19j4yxDo/pBzAPF7xKz2Gpi4/VzJDPuZFIL2r0To9pdV6P7p6fz/GSD43N7G7tSaLgj2zT/Y9ddAHuWkKyjZLJH4/GkkGv2erqbmJxq055PNZP+ZynDkBOVG/3oQTP7Tm3TkNdzA/RBYXOWUHlbc6djk/f7dUPwCfxbhAeQE5OG8OP147wb5pG8G8+N3uPV4aaz/ZzA85z9x2vyyShz6/5wI6YEUivJiImD0UU2k/TCxlP0kLnTyp+Ie8ps3jPuGChL1o0Y8wuc/gMa12fz8eLp09ZwYgvZu5LT1U0X4/VvwYPrezBr77VvK7ot56P34UK735j7E9G9bKu43Ofj8WMW++hS2xPRZTC7za63c/F6Eav1axsL60o7a+B6EfPwnXqr1zlS8/v2f4vlszCT+DeSw/vQTAvcjjGz7Yjjc/JAXvPcUjP7vLaTe9q/19P682Hr8dgqM+SgepPo5VIz++rSm+A70tv4YAAz8HBgA/fDw3P7KOgzvO3ns92RMyP1QyQz7tRSC9r9E6PaXVej894n+/FbvwvJ5zbTu4pbc7oTS/PbeVFzv/0xu6keF+PyswuL6Eksa70XqZO2rabj/KHUs50Wptv5aCvz49zPs5gjwfPyDmaTwgtua6RWpIP2T0Nj/bETw8hWc9vLgDMz+kjcy+rY61vQ695D1A02c/INEPOc/cdr8ukoc+A+wCOsIAdrzWU5g9Z5JuP8QTZT+MIe48fS3OvES14z7cgoS9lAItMtgV4jGtdn8/V+unPR0GVr0un4M9YUF+P1ZtGj5E4ja+b2MovNnkeD+u4ju9JtfwPeIrGbzq8H0/kB1/vvaG8D20wzW87hR2PxehGr9WsbC+s6O2vgihHz/+GCm9crQtPyZMAL9CFAk/aH0tP3NEEL5mNVE+/TMxPyQF7z1xJD+7zGk3vav9fT9nZB6/stCiPiRQqD7QhCM/lPQ2vsE7Mb8eme0+sdwFP9IGMD+sjV+8OR+cPVPROD9WMkM+7UUgva/ROj2l1Xo/1S9/P7wEMD37nq27heSIPRe7vj78Zg48W9Nwu9GPbT+oHsW+ivMXvAvDFjw3Pmw/vtMPOc/cdr8skoc+s+oCOpM5ID/9IsE8dIE+uymRRz8LLQU/BXdMPAJzAbyMmVo/ftndvp2JQb2c9AY9ij9mPxXMDznQ3Ha/LJKHPi/qAjq4T4i8uD2YPUkhbD/aCWU/tfYDPUWD5Lxqq+M+14KEvS6fMbJj+GMyrXZ/P/97kT23rnS98eKKPZNNfj+KPw0+p21OvtWvcrxnN3g/voQLvbyBCD7/q/q7xY59P2PPdL5IZAg+excavAU3dj8XoRq/VbGwvrWjtr4HoR8/wKYDvPAzLD9OkwK/FzcJP9KlLT9cGjS+rHV8PrFhKz8jBe89XCQ/u8NpN72r/X0/Z2Qev7LQoj4kUKg+0IQjPzaoOr675jO/V5vXPk0vCz+wwyc/leDQvKh6qj1BFEA/WzJDPuZFIL3S0To9pdV6P9s8fT/hZjw9wtW5u2NRDj7gpgg/dEJOPIdoAryAcVg/kh/WvgRMF7zyOks8CYFoP5O/DznP3Ha/LJKHPkXqAjqk7TQ/pmf+PEvwervg7jQ/sciGPtmD3TsQGPO6ufZ2P7us9L7VUXY8ENRgPADRYD+w1w85z9x2vy6Shz5v6wI62WyLvCE4mD0xBWQ/YgdlP2j7Bj1Lvem89ajjPtqChL0r4N+xUL2SL612fz/Tjl49JtV+vQaUgj09mn4/Hz/3Pfn4U76UtKu8oXt4P2ZDibx13gw+DohUu0aHfT9sc2O+HtAMPqmgpbtNG3c/F6Eav1ixsL6yo7a+CKEfPwE9dTtfQSs/0IQEv2KMCD+AaS0/IIdGvn0lij5rBCg/IgXvPTUkP7vCaTe9q/19P2hkHr+x0KI+JFCoPs+EIz81mjq+vTI1v/JLyz6JGw4/gWkiP/zx0bxeU6U9cbFEP1gyQz7pRSC9qdE6PaXVej/YX3g/btw3PTVbtbtGtXM+0CguP8EFeDz9kWq8g407P8V18L5XxuG78QJ7PDb4YT/ewA85z9x2vyyShz4l6gI68alJP3ioGT2ZkJe71mUdP3FSED66hIc73usdukFxfT8NpxG/IdXpu4ZJ77uWglI/QcwPOc/cdr8tkoc+1OoCOhL+WLzfZpg9R/ZVP2cdZT8ICtI8/tq1vNm+4z7fgoS96hI8si5yzDCtdn8/+w0hPU4CX71Qo009NRl/P/sp3z0Q5za+J0eHvFBMej/i4z67JAnzPYtjfbsiMH4/sjlEvoel8j1Q9vG7RGl5P9mxGr+ddrC+Eme2vluyHz/nuQK8p88pP9j8Cb+o3wQ/460vPx4IM757l4A+vewoPyIF7z2LJD+7w2k3vav9fT8mUx6/yROjPmWVqD74ciM/sbI5vqo3Nb/FKss+DzQOP7P+IT80zim8TNeKPX1yRT9XMkM+6UUgvbnROj2l1Xo/ajZtPzjrAz0eH4K70s2/PrMVUj89BVM8Oy+WvB4tEj8LeQa/nRz1uhOlbjwGzlk/lcAPOc/cdr8tkoc+GeoCOhPbQj+SG+08o+Bpu6vdJT/+NpU+3LjEO1o+ALvB4XQ/9hMov7EYE73sUwq9ta5AP6KRIjksQnS/+UeZPu+JATrMMr675KeYPV6HSz+wOGU/7Qc4PEtWH7z42eM+4IKEvdFYTTIIBKWurXZ/P9Z+8TyXEKO8lU0UPYerfz9fZtc9nAePvWMN4zsE8n0/n1uSOzPdNj2BNYK8t7V/P9LDGb4+FzI9KWyavHLOfD8z/hq/1WmvvpxRtb5GASA/9Ws5vVl4Jj/iWhW/Yw34PkEXNz+7T6C9TJ4ZPtSZLT8dBe89hyI/u81pN72r/X0/5gMevxpGpD6j0ak+DSEjPwUKML5XOTS/qlHVPsqBDD/t2yQ/mbzaPGYlGT1Hf0M/YTJDPuFFIL3D0To9pNV6P+vyTj9RnTI8ui6wun+qFj9aTGg/y+3LO/yuXLzHBtc+tDMFv8qxLLxPxgO93nFaPyTaDznQ3Ha/K5KHPp7rAjqYBS0/OektPN6Kq7qFqDw/Dbj1PiP1kjtjgCG7kZZgP/YFq75Fs6U7qXNJO49KcT+AyWc5S4Bnv+eR2j7piPU5KWbtutazmD36WVE/cj5lP72vZTve3Ua7JODjPtmChL3gl8cy7BhzsK12fz8hfgo9jHGXPA4N6DwBtX8/6QfjPVqvQz2Blqw8IBJ+PzdSnznGvw29iWCtvA7Kfz/lLSi+OIASvcoJnrwxT3w/xokbv+x4rb6fULO+jJEgP8YUz737UiU/16oZv9P36z7q5To/0QUHPQI/Aj29jC4/GgXvPbYjP7vLaTe9q/19P0VwHb9QeaY+DxesPnGIIj+Egxa+hnEyv4pj5T5pSQo//CIpP0qfqD1/UkO8Hfw+P1syQz7pRSC9q9E6PaXVej++eSA/5fsOO8QJjbkcdUc/rd1ePyq1Ezsjtpa7x+n7Pq653r46LSM9jWv3vWoyZD8lyA850Nx2vyuShz736wI6VKVJP14TdDtpwfC5D7cdP6vuHT/dpvE6MOTNuiF6ST9U+wG/tAYuOtJmuTrNi1w/yViUOZNnVr+B4Qs/5WXjOf4AKzvesJg9JIhhP6o9ZT9VdKW7+UCPO97f4z7qgoS9E8ZhswN+OzKtdn8/PGcsPahZLj1DBjo8PYZ/PwER8T146P89ugndPOsafD+O1OW7eRewvYidobzh/n4/kqVCvpeAsb3XDoi8rFB6P6svHL+jIKu+7uSwvgk9IT89Qw6+XygoP7TnEr+oG/A+8OM5P+6Wnj2tTnq8lNkuPxsF7z3JIz+7y2k3vav9fT8FvBy/ThypPufPrj4dziE/MLfhvVlSML+A4PQ+e5kIPz74LD/iHRI+gfGQvbZEOD9YMkM+7EUgvajROj2l1Xo/glEWP+KzYrtyqd85/DdPP0qxND/W7US7sxInO71XNT/7Ndu+RafGPb4arb07/mQ/hLsPOc/cdr8ukoc+JukCOko8fD/u2AK8ZhKBOsPELj4+hEs+01ScuZ7Ekzed5Ho/GBsNvwLqjDrpscG5qplVP0Tmjjk1q1m/yb4GP2Hc5jn0Dgw8uJaYPYnYbj8cMWU/jYeHvPmvajxy0uM+14KEveAEN7HGM4YxrXZ/P5qiTz13uGY93Y5DvOA+fz+HlPs949gxPkAnBj3z/3k/Ul5nvPzo8b2qSJO89CN+P/LCW74Gj/K9aheBvD4oeD8t2hy/WqyovlVcrr5F7SE/mxImvnXvLD/ChgW/rpX9PjHFND8DU8o9KHEMvcZHMz8hBe89WSQ/u8RpN72r/X0/J/0bv5fYqz7RorE+zgghPzVUib2pOC6/hiIAP0DnBz/Yhi8/C+xLPjQ3B75LBjA/WTJDPuhFIL3B0To9pdV6P0I3Jj98oWm883LmOnCqQj/Spd4+4SLIuyCaQDtohWY/ky/rvtXLDj3AL1G87DFjP0zGDznQ3Ha/K5KHPlrqAjrqzH8/8fnQvEIhTjsIdPW8PHotOx6uLLp6ogO3wv9/P99W5r49apk75JgXu26gZD8aID45TctvvwhGsz5EUv45tnhlPPBfmD0onm0/aBllPzYe3rw8UMA84rrjPtqChL3zs/yxbpDsMK12fz8rz2o9Z658PfK8CL2L8n4/8LgAPmr5ST5skBg9a7d4P+PqnbzbjQi+CQmHvGWhfT+FD2a+vsMIvvVEcbyHEnc/5G0dv0uCpr5YIKy+/IUiP3LSMb78cTE/8U/svrWUBj8QyCw/lQ/sPbcWNL1TPTo/IAXvPdgjP7u1aTe9q/19P/dSG7/qPK4+9Bq0PuVYID8kYua8IaIsvxbfAj8XNwg//Z8wP6VneD6j/T2+UAIoP1gyQz7sRSC9wtE6PaXVej/nqkE/CpXrvJlfaDv6QCc/dr0hPq3Zb7vmCVA64Mh8Pw/B677zWiS8Y9O8uy46Yz8A0A85z9x2vy2Shz4V6wI6/Yt/PwOSJr01TaQ7R5IwPbn4lz7zm+a7rtsRO6l0dD8NTrK+dYX+O7oW+rtf9W8/CMgPOc/cdr8tkoc+AOkCOsV1jzxSMJg9LLxoPxoEZT8i5Qq99IPwPLKl4z7egoS98ErhMnCpfbCtdn8/Ql97PcmIgT3fM0G9xrd+P9RfAj7I8VM+Mo4jPb4deD+Sgre8h9QOvu15frzDZn0/BgBpvv4GD75EW2C8o652P4XXHb9q8KS+cYGqvi3zIj/jKDe+dWI0P0Vr074tcww//ZolPyYh9T1KqCy9g39APyMF7z0yJD+7tGk3vav9fT9z1hq/C/avPlfitT4u2B8/HcUqu4eKK7+yNgQ/uHwIPxzGMD9c1Yo+WlhlvhjOIT9cMkM+8UUgvczROj2k1Xo/pMpXP3cJK73KtKg7UU8JPyU/LTscJY665r/htrz/fz9xw/m+ZzPdO1FCrjyaZl8/lr8POc/cdr8ukoc+3esCOobqfT9m2E29TQrLO69G7z3W79Q+27k8vL4vsTuDyWg/XuOevpJo+zvq7T68vVVzP8a/DznP3Ha/LJKHPhfqAjrMX5o8gBuYPZINXj/B+mQ/IHoVvXZrAT1lnOM+3YKEvVTd4LHzuIGxrXZ/P/6qgD0QkoE91pZWvZ+gfj8W+wI+VwlWPiWfJz0t+Xc/5NLAvEkQEL4V2Hi8Nlp9PzEZar6RQRC+7nZavOCSdj8qBB6/EkWkvpHQqb5UISM/tuw6vhpzNT9Stci+0K0OP0dEIj+FLds9mmHsvMb1Qz8pBe895iM/u8BpN72r/X0/F6Eav1axsD60o7Y+B6EfP8e4KTvv5Sq/IMIFP3TJBz9OmzA//gyRPrTPdr5U/h4/WTJDPuhFIL270To9pdV6P9kuXD/NC0C9LW69OwsJAj8hIC07R3mbum8s2ba6/38/38cFv4YExzzztjQ9u+FZP3rDDznP3Ha/MJKHPsHrAjryQng/bulUvfsC0jtDDHQ+NoAWP9bEhLzW10A8UAZPP8j+ub7OXa077+9xvCN6bj+RwA85z9x2vy6Shz7p6QI6vt0EPapVjz7qQfA+mURgP46L8jyERey9F0DvPuOChL0tKWgz0AWhsK12fz+Uejs+7vUePcv2/D0We3k/pRaKPsKuGz0rP4G9fsp1P+DkOzxw8uO8qH7EPHPPfz+oKKi+d05CPfFnUbyyeHE/f44PvwTH0r4i09m+YS8UP0dCJrxoWCI/N0EdvzVe8D5Jw8Q+uUWDvmVd5T3+OWE/SPiHPQYpVL6Wdo69ezt5PxehGr9UsbA+tKO2PgehHz/H4ci7e6Ejv/oMGj8jK/U+/BsVP23SYj4PAi2+VH1DP4Y+qz3iZQw8r8pZPQy7fj/65bk+LTg4Pta1tbz6+Gk/Jf07Pw83UryrRWM8BLQtP5nS375fPVI9i4YcPdaoZT+lxQ85z9x2vy2Shz4C6wI6CAg2P8scDb3CMIs7OsgzP5K7aj/k7y686zvJPLfbyz6VsSS/FkkBPdwsZ763GTs/O3ixORfDQb8PTyc/v4bNOT5aBj3XZI8+CoTwPtsaYD+Ceus8hwvrvar27z7ZgoS9ogQEMzs72bKtdn8//n8+PrLSHT0ApPc9jmx5P954iz6M8Rk98AaDvcyVdT80pws86wzfvLKZzTyr0H8/VdahvvTkUT2UWJe8Y3lyP4GOD78Fx9K+I9PZvl8vFD8S+jW8WwgiP78CHr8LN+8+Fr/EPrZmg74Hl+U9LzVhP/hpfz1OYlS+GmuQvWpFeT8YoRq/VbGwPrejtj4GoR8/a6cOvPLWIr8ADBw/7i/yPoAUFT+GWWM+E2ktvoVzQz8ItZ09ABYAPB0OZT2I1H4/DCu7PlV1Oj4u67e8TptpP9TZOz/T5Hu80f6HPLrSLT8a8t++8lxSPctwFz11pGU/FskPOc/cdr8skoc+zOoCOmRGNj9ImxW9fZGTOwSCMz/CqWo/EHgrvJjaxDyyMsw+96okvzOu9zwNk2a+FS87P2ZVsTkJ3kG/1i8nPxakzTk0Hwo9woqPPkos8T4wsF8/vp7ZPO3q572UxPE+1YKEvXzIC7OmG4sxrXZ/P/sGRT7F5xo9BzPrPWlNeT+sbI4+pxsWPWCIhr0KJHU/4LQPO2kn1LyNEOE8HdF/P7Qelr42Bm49i7nxvPQtdD9/jg+/BMfSviTT2b5gLxQ/VOZLvPGUIT9hFR+/VpHtPp24xD6LmYO+6+/lPcItYT+ZLnY9yoFUvlODkb16Snk/FqEav1OxsD60o7Y+CKEfP5XcR7y/qyG/u98eP7Dj7T44BxU/eEhkPl8fLr4dYkM/jSWWPUHn8TsMVWs9TOF+Pylovj4VKkA+y4u9vDCoaD9kdDs/6DqrvI0suDxhKy4/XCPgvmvcXz1+CBo984llPwS8DznP3Ha/LZKHPlDqAjraMTY/J1wsvV4DqjsmgjM/65FqP2sEKbxYisE8zKPMPiuqIr+lEtA8ejlmviQAPT9ycLI5IfZAv0k7KD/xq8w5hSoPPTW8jz7FDvI+pB9fP+XcwTwgsuO9NSz0PteChL1G78mzm4OWsq12fz+6UEs+6hUXPfnQ3D2WM3k/OTCRPouOEj0SFYm9rrh0P/1Le7tDT8m8ZnLzPMbOfz+z/I++GPN/PfOsE70g+XQ/2JEPv3eN0r5HJNm+qYAUP4h+Trz4hiE/SDYfv5te7T5N98Q+VDSDvn4C4j26PmE/8sB3PXR8VL6YU5G9pEl5P4bNGr91FbA+yQK2PvPOHz8Zfk68+4Yhv0Y2Hz+XXu0+agUVP+JoZD4XOC6+vl9DP/Nulz1wW/Q7wENqPTPffj9JwcI+75ZHPrLexLxfW2c/CeM6P48F5byd9vQ8GaQuP1tU4L4BeHY9TGIiPQ1hZT/9yg85z9x2vyyShz4r6wI6vd41P15cS72Bl8g7ebUzP1F1aj/v+Ca8vZ2+POkpzT5yVh+/rCKXPEHlZb734z8/11e0OTdgP799CCo/2f3KORl5FD2z7o8+tP7yPlSFXj/iCqk8dDXfveew9j7bgoS9P6M1MobleDGtdn8/v7hNPkOYEz13hdE9Fz15P1UTkj73PxI9TiyIvRmZdD+gyMO7HVbFvMf1+TxKzX8/LfWQvgEmgT1WShK92dJ0P/OeD79FcdG+ENjVvrMIFj/5fU68+YYhP0g2H7+bXu0+YC7GPnMogb5B2c49y49hP3itgT27VFS+k/OPvSVDeT8Dohu/3SGtPsP2sj6aqiA/bn5OvPyGIb9GNh8/ll7tPmsFFT/caGQ+DDguvr5fQz9q76A9mxMDPCNfYj3Dzn4/0FfHPi8nTz7CVMy8M/RlP98/Oj/3DhC9UiMZPSkkLz8gduC+L6yIPYUQLj3BMWU/WsMPOc/cdr8skoc+OeoCOpRkNT8Xlmy9LF3pO5UHND/ZVWo/N7ckvJpquzzovM0+kWEbv4zaMDxLamW+VS5DP0ectjnddT2/NCosP3D2yDkqBRk9vxiQPqnN8z5N/10/ZeuTPM1T273K1vg+24KEvaC21zBVi9KyrXZ/P1aGTT5T4hA9wKbJPT1beT/EwJE+HssTPfC5hb3iqXQ/TRa2uxmixbzcn/k8ec1/P3v6kL5UJoE9YCgSvSTSdD8eqQ+/G6jPvsLG0L7oYRg/hH5OvPqGIT9GNh+/nV7tPskayD7l63u+/nGxPev6YT8Km4o9ixZUvj/Xjb0TOHk/COIcvxWPqD4cPq4+afUhP5Z+Trz8hiG/RjYfP5pe7T5rBRU/32hkPhM4Lr6+X0M/G5CvPVMzEDwnMVY9NbJ+P5lIyz7lhVU+P53SvOy3ZD8jqzk/eu4ovW2VMj2fky8/8oDgvq2zlT0dtDo9lARlP+fTDznP3Ha/LJKHPi7rAjpl2zQ/iwWFvYM1AzzAZzQ/9DhqP5r6IbwAvbc8NkTOPuqLF7+H03s7BNFkvq47Rj//xLg5uJQ7v/M1Lj9S98Y5+scbPboxkD7xS/Q+G61dP20ohzxM9Ni9jyP6PtmChL1y+oiyoOCcsa12fz9Qmkw+tEcPPcc9xT1mdnk/iSuRPqBGFT1f7YO9EMN0P8ick7sctca8ZF34POvNfz/+GpG+8Q6BPXzvEb2mzXQ/FqYPv4iFzb4xDcu+PgcbPzx+Trz6hiE/RjYfv5xe7T4hXMo+Z4t0vkpLkD1cWmI/FreUPW3OU75odYu9+il5PxNCHr8BVqM+wtmoPlNhIz9Sfk68/IYhv0c2Hz+VXu0+awUVP95oZD4SOC6+vV9DP4whwD1iOh48jFpIPRqNfj/1rc0+eJRZPqKd1rxj8GM/MUo5PwoGOL0g10E9odovP0114L54q589GPpFPQbjZD/Nxg85z9x2vy2Shz6A6gI6kFo0PzXojr3p9Qw87Mk0Pzkoaj+M8h68uPizPAqUzj45pRS/hleGutlaZL7wc0g/4mm6OQsfOr/0xC8/q2zFOfvHGz26MZA+8Ev0PhutXT9kKIc8R/TYvZAj+j7fgoS9o10OsjrdrTGtdn8/VulKPmtxDz0pKMY9gYl5P95ZkD5imBY92yGDvfbidD8Jlzi7avnIvJKj9TyKzn8/WY6RvnXFgD2FthG9Q710P4qVD79BcMu+CcTFvtR2HT+Cfk68+YYhP0g2H7+aXu0+C4XMPgmXbb5/gmM9O5piP0sTnj0hilO+tEKJvW4beT8jfh+/pHWePv3Qoz4RqCQ/sX5OvPuGIb9GNh8/mF7tPmsFFT/gaGQ+Ezguvr1fQz9cec89qWwqPAqAOz03Zn4/hK3NPoJAWj5dR9e8DeZjP4NCOT/sUzi95xhCPRziLz8fWeC+TuCjPeuXTT1T12Q/TsYPOc/cdr8tkoc+3+oCOsn5Mz8PC5G9ThEPPF4jNT8AL2o/i2AcvPgrsTw4eM4+9YITv6o9IbvaaGS+uEhJP+Yquzk7eTm/4nMwP7W9xDkwBRk9vhiQPqnN8z5M/10/YeuTPNNT273M1vg+14KEvQiX9DGuRsQxrXZ/P2JySD59bxE9DY3MPZWTeT80TI8+vO8XPaYvg72ZCXU/ec0AuvXUzLxp5PA8KM9/P/KLkr6+MIA9lpcRvbaYdD+tgQ+/WePJvgUAwr4FMh8/h35OvPqGIT9INh+/mF7tPrAazj4ujWi+fxU4PWi5Yj/XwqQ9dFhTvvKxh70rEHk/DFogv/Tzmj48MqA+aoslP2p+Trz6hiG/RjYfP5te7T5sBRU/3mhkPgM4Lr6+X0M/SG/aPXKrMjyKSzI9xkd+PwtIyz7f/1Y+CBLUvJOhZD/vmDk/XbEovfcuMj2Apy8/LT3gvsQ/oD0TuU49budkPxnHDznP3Ha/LZKHPi/rAjpA5DM/2bSJvZ3UBzz/TzU/uUtqPxP+HbyVirM8WPPNPoOsFL8/buU5sDJlvipfSD9zqLo5Z+05v3X5Lz/6NcU5GXkUPbbujz60/vI+VIVeP+4KqTx5Nd+957D2PtuChL2Y8acyUrsRsq12fz8dSkU+YKgUPSn91j3Zlnk/nQGOPiR1GT2vSIO9iTh1P3OhHzu1Z9K8ufvoPKvPfz94T5S+kHx+PVYEEr1dVnQ/enoPv79qyb7A4cC+c7UfP5VbTry2hyE/kDQfvz1h7T4Flc4+EQpnvh0zKz1mwGI/6damPdlIU76aNYe9hQx5P4CaIL8K6Jk+oh2fPg3OJT+jJU6864ghv70xHz+SZe0+hAUVPyJnZD61Ni6+3l9DP5XX3T1OJzU8BG4vPdw9fj+vV8c+LM9QPvP2zbzk22U/6Sk6P/Z2Dr2nSBc9aj4vP4ok4L7WY5Y9SUhJPQ4NZT+nww85z9x2vyuShz4H6wI6Fho0P4gId70Gq/M7D0Q1P59yaj+9CyO8RQ+6PC87zT6Amhe/NBjYO5xUZr49E0Y/HyO5Oe9CO7/YjS4/RKjGOYgqDz01vI8+xA7yPqQfXz/h3ME8HrLjvTks9D7dgoS9+jABs2CU5DGtdn8/5tlBPghHGD03quM9z5J5P02fjD7Qkxo9bdyCvcNrdT+Ry7c7S5vYvPme3TwQ0H8/Oo+XvvRfej07aQ+9b9xzP++TD787S8u+xWjFvtqgHT/vKEe8SK4hP4jZHr+F7e0+OqzMPpz5bL76I189CKBiP5JPoz1KY1O+zwiIvawSeT8okx+/6iCePoN5oz7LvSQ/WK07vCXuIb8nQh4/L9XuPmUKFT+GD2Q+5fMtvkNmQz+jDtg9COowPC5LND2RTn4/JsLCPk36SD5PPca8qkdnP1jOOj+98t68VzjuPIa+Lj8zCeC+oTCJPdRdPz1fPWU/x9MPOc/cdr8skoc+RewCOgWEND+kJlS960LRO34HNT8YmGo/gBApvMu4wTxMh8w+e3Qbv0lIbDw/Tme+nPdCP1QLtznyFT2/h5MsP0KVyDkzHwo9w4qPPkos8T4xsF8/uJ7ZPOzq572SxPE+0oKEvUOgpbO6Qn2yrXZ/P1ixPj6lmhs9JPfvPZeJeT/QXIs+YkQbPfEsgr3BmnU/l4ULPKNE3rzOt9E8AtB/P1Annr46TWc9NifgvEHzcj98qQ+/YpjOvrLjzb7Ltxk/sJY5vKz1IT+RLx6/b/LuPr8/yT6T1Xe+tF+gPTM1Yj/0tJs9jZtTvu7Qib0/H3k/1pQdv7DupT7xh6s+QK4iP2k2GLwUpyK/OIIcP7998T6OEhU/pnxjPuaDLb73cEM/b5fLPe1oJzyXwT49d3B+Pz9qvj5dCkE+EGm+vPubaD9MZDs/PrKjvALsrzykQC4/b+vfvjPwdj0NITM9tm1lP+fPDznP3Ha/LJKHPsvrAjq7CTU/CAQyvU+Xrzs3pzQ/UrNqP4UBLry8+8c8HQPMPnBpH7+MoLY8YspnvtSoPz+ByLQ5YQQ/v6FvKj+wnMo5RVoGPdZkjz4IhPA+2xpgP3V66zx9C+u9q/bvPtqChL14Wksz5Po0Mq12fz8oYTw+zAUePcdE+T20f3k/0HGKPgOZGz03iIG9H711P5dYLjxBXeK8ZFLIPKnPfz8SAaW+lsJOPV0VkLxx9HE/C54PvxmJ0b7MHda+XugVPy1LLLzvOSI/L4sdv5bt7z57HcY+6QWBvijlzz2YlGE/mvORPVLiU77qG4y9/y15P5eQG790YK0+XjezPpmYID9Wg+m74FQjv2LQGj+fCPQ+TRkVP9kCYz73Ji2+0XlDP+qZuz1Wexo8QCRMPcCXfj9tLbs+Usw6Pv5AuLxrlmk/rtA7P+oHcLxlhoE8594tPx7U376s0l89LsMmPWyUZT/XxA85z9x2vyyShz4x6wI68pI1PxHlF71n05U7kzU0P5m/aj/aWzC8CffKPCPHyz4OuSK/C/rpPNa0Z76/zjw/0L6yOSWxQL9Iiig/MWnMOb7dBD2qVY8+6kHwPplEYD+Oi/I8hEXsvRdA7z7jgoS9LSloM9AFobCtdn8/lHo7Pu71Hj3L9vw9Fnt5P6UWij7Crhs9Kz+BvX7KdT/g5Ds8cPLjvKh+xDxzz38/qCiovndOQj3xZ1G8snhxP3+OD78Ex9K+ItPZvmEvFD9HQia8aFgiPzdBHb81XvA+ScPEPrlFg75lXeU9/jlhP0j4hz0GKVS+lnaOvXs7eT8XoRq/VLGwPrSjtj4HoR8/x+HIu3uhI7/6DBo/Iyv1PvwbFT9r0mI+EQItvlR9Qz+CPqs96mUMPLLKWT0Mu34/+uW5Pi04OD7WtbW8+vhpPyX9Oz8PN1K8q0VjPAS0LT+Z0t++Xz1SPYuGHD3WqGU/pcUPOc/cdr8tkoc+AusCOggINj/LHA29wjCLOzrIMz+Su2o/5O8uvOs7yTy328s+lbEkvxZJAT3cLGe+txk7Pzt4sTkXw0G/D08nP7+GzTmEv+w8TnSPPuSj8D4kH2A/URkVPTYH+b10vu4+04KEvTRGmbJpX4qyrXZ/PwY8RD6j3Sg9UNAKPo+feD9lQ48+3C4UPV5QiL39AXU/0x33Oons4byHwMI8btR/P6jDrL4Tc0E9dI1gvByocD9+jg+/BcfSviTT2b5gLxQ/BHUnvP1ZIj/BPh2/KmDwPgPFxD5VOIO+AEblPfA7YT8ZWnU9l4RUvoickb3rSnk/F6Eav1WxsD61o7Y+B6EfP17zz7sppiO/ggUaPwYx9T7jHxU/yItiPinMLL5zgkM/hneVPWKa8Dti5Ws9ZeJ+P5csuD6Hjzg+4Qu2vNFLaj8T1zs/UOQGvJh4ETxW5y0/LePevknrYz2glx89ENBlP6DYDznP3Ha/LJKHPm7rAjrNeTY/PxjyvNDLbjuiYzM/DZxqPxXAzLsiPmo8ZbrMPho8Jb+LJAk9XAJivvj+Oj/+PLE5pfZBv0kTJz8Swc05ds0QPeGSjz6z8/U+aqFgP44rBT3sofC9UoPtPuWChL2GuwYzsI8IsK12fz+uYUE+D+giPYR6AT7IF3k/fFKNPh0sGD0wUoi9okd1P/uyqju5n9686VTTPBbRfz9UPqu+x11FPebUPbxT7HA/f44PvwjH0r4i09m+Xy8UPyVZRrxHtCE/mssev5UC7j7DusQ+toiDvmvS5T04MGE/KFp1PZeEVL6JnJG960p5PxehGr9YsbA+tqO2PgahHz/Zvye8hGAiv1cwHT8tdPA+yM0ZP3dHXz6RHTO+Nbo/P4x3lT33mfA7YOVrPWTifj9Q6rw+tdQ3PrVTtbwYY2k/wWI9PxmDZLxiMns8TyosP8pm6L5PuEQ9tW/3PDmlYz+5yA85z9x2vy2Shz6U6wI6cFdNP7qMIL29XJ47Y4oYP9TxZD+w6Bm8bcGZPAbW5D5EqTi/oOmGPCFfar7ISSc/hCjDOZxIRb86JCM/2c7NOQObHD3MXI8+lMgAP9jJYD9q2LQ83T3dvQho7j7dgoS9EDCrsd2ftzKtdn8/rxE7PmUxFD27ZtM9JSF6Pzj0iD54bSI9AGSGvbbjdT/hmU48HR3YvJEZ+DzoxX8/5dinvq+lTT301+C7N4FxP36OD78Gx9K+JNPZvmEvFD9p4Uy8A5AhPxAhH789f+0+Y7jEPkebg77j8uU9gi1hPzRadT2fhFS+jJyRvepKeT8VoRq/VLGwPrSjtj4JoR8/qmFMvE6TIb9pGR8/5IrtPkCVHD/bV10+agQ3vpJfPT+Ld5U9C5rwO17laz1l4n4/XgbNPkdPNz4G0LS8Sf1lP9FqQT+aq5i8ySKwPJSMJz+nZwC/hw7BPHsquTx4T10/gcIPOdDcdr8qkoc+EusCOm3iYD8TOUm9UHvGO4xU8z6YHFo/pMU4vFNSljzq6QU/8BtLv+YsOjxE+V2+gZURP+6l6TlGy02/+0MYP7P70jly6Rg91NGOPr/+BD/Tg2A/u+rlO0fqwb1CJvE+34KEveD/BjN2rp6xrXZ/P6huND7QcAA9QC+RPUY2ez8nKYQ+vWUwPRnmfr2BkHY/czqoPElw0rxonw89OrR/P5oxpL7D1VU9++rqui0ccj99jg+/CsfSvh/T2b5hLxQ/eMA1vG8OIj8C9R2/50rvPnHAxD4YXIO+iITlPbo2YT8uWnU9nIRUvoeckb3qSnk/F6Eav1ixsD6xo7Y+CKEfP9kPQLz62SG/xnIeP/6J7j7Koxs/AQBePvWtNb59Lj4/i3eVPfeZ8Dti5Ws9ZeJ+P25C4T53kjQ+zhyyvA5ZYT+Ly0g/ndCwvPzj3zyYjB4/fZcRv1OnRLy4LZg8BH5SP9/EDznP3Ha/LZKHPuzqAjoaZFM/Q5NLvTHNyDsS0w8/v4hgPwPVZrz71NM8snf1Pq2uUL9TB5k8tTBCvkYHDD/X2Ag6u3lZv5IOBz9iLuQ5IVgJPWcVjj6YXgY/EgBgP3UxKrwQyaG9a330PuuChL1tc6SykLbwMa12fz/K6TA+/oLVPDPiED1E5ns/lP+APooWPj2IT2K9Sg13P9ALzzw/p8+8EkQbPd+mfz9cAKK+7mhaPSrKojqadnI/f44PvwLH0r4k09m+YS8UP7xwD7x01CI/chIcv+Ql8j7fy8Q+LwKDvnLn5D3SQ2E/Mlp1PZmEVL6InJG96kp5PxehGr9TsbA+tqO2PgmhHz+z9Au8EPMiv//IGz8lkfI+vr0XP4u3YD7xSjC+CGxBP4t3lT02mvA7Y+VrPWXifj+Y5fk+SrQvPoNPrbxgAls/ysZRPzsexrwk+Q09uFQSP7XqJb99GFe9Zi2rPPNqQj/I2g85z9x2vy2Shz6i7AI6VaUBP8AMwryYaD8716hcP60+Zj9UKjS8DYi6PMRw3z5bxiC/XUs8Pboz570QwkQ/7jkZOmvoZb86MuE+M38BOsiX4TwgU40+On4FP5d8Xz+VmOa8qRCAvaM89z7TgoS9efQgMhyJQrGtdn8/zrozPpUjqjxkXx47F/h7P1hAgT5DuUc9EAw0vUUjdz+OusA8s6DQvOP5Fj0KrH8/lc+ivhXAWD1TZAA5cFVyP3+OD78Dx9K+JtPZvmAvFD9779W7HYUjPw5WGr8zvvQ+wtTEPiS8gr4NbeQ9/01hPyladT2ahFS+jZyRvepKeT8XoRq/VLGwPrWjtj4JoR8/FeqQuwI6JL/ZhRg/P2X3PgfhEj+fH2Q+Ed8pvlI/RT+Md5U9nJrwO3Plaz1k4n4/ps0NP3m8Lj4YW6y8NotQP82XWT/Ol/68EtBOPcsCBj8D7zu/IMqyvZnrAj17MSw/7cEPOc/cdr8tkoc+N+sCOplgzj7QI7q8Rpo3O3I1aj8dLU4/2KOeOzLM1LvJuxc/CS30vqvSAD0ADDm9EpJgP7rEJTr4AXG/JaSsPqgzFzp2C6U8KcCMPn4xAj+BRV8/A/E1vdkJQb0oSPg+3oKEvbDXADOeZ1UzrXZ/PytSOz7MKYI8rFTKvGKRez9TOoQ+0uhNPYS6+bxr23Y/1DOJPAL91Lz0SAY9aL1/PxLxpb4BAlI9QySKu7XScT9+jg+/BcfSviPT2b5hLxQ/4lO3uzDMIz9dnxm/08z1PvzXxD65ooK+pUDkPa1RYT8fWnU9n4RUvomckb3qSnk/FqEav1OxsD60o7Y+CKEfP+tkqLo5HCW/LyYWPyHW+j7YSA8/26dmPsRNJb5z7kc/kneVPfyZ8Dts5Ws9ZOJ+P4KLIz9+ZjY+fuqzvOODPz/Gkl4/KhMyvQtMnz2sz/g+uohRv8jT070Ix1895P4PP3TPDznP3Ha/LJKHPiztAjrcQ84+5lO1vNDbMju7PGo//SY+P7Z0IzwnnzW8nlsrPzzX+L5V1Fm6xgsCvU+VXz+QZDY6y9x2vyGShz6VISs6oqtFPFZ9jD76vvg+kn5fPyQDa714vg69F1D3Pt+ChL0S/IqysII/NK12fz9L8EM+9rREPOfONL0p/3o/xxCIPnF2Uj2KI5W8UWZ2P7YcDTw7fdu8+kPkPJbMfz/wrqm+pj9JPcU/GrxOMXE/fo4PvwjH0r4g09m+YS8UP4D427vodiM/Tnoav1SI9D4Z1MQ+asGCvjZ25D07TWE/I1p1PZuEVL6GnJG96kp5PxahGr9XsbA+sqO2PgmhHz8OTKG69R8lv+sbFj/j5Po+MDkPPwKzZj43OiW+3/lHP453lT0xmvA7cOVrPWTifj+ovjc/AV9APg/Avbwbiis/XHVjPygUQb3i+b89BLbkPn8fW7+svMe9MvraPVEn/j5YRDM5wKVxv8gGqT7bJgA6wNW+PvyjurynHDg7AHttP5rqPj/6AxU8NxMnvFWDKj/lYAq/W0XWvMewF716EFc/V31SOsrcdr8gkoc+A9gyOhfFgjvFg4w+/RDvPpr7Xz+zNIW93irjvJpG9T7WgoS9BEQlsqri1bGtdn8/z+xJPn31Hzy2Vl+9jJJ6P9zbij5hY1U9rpMrvIwHdj8BKTk7LffgvAhyxzyX038/llWsvgySQj0KvFa8frtwP3+OD78Gx9K+INPZvmEvFD86fhO8H8AiP7lEHL842vE+xsrEPucKg76x9uQ9jUJhPzBadT2fhFS+iJyRvepKeT8XoRq/V7GwPrKjtj4JoR8/BYWMuxVEJL9Uaxg//4v3PiO5Ej+RO2Q+gKspvsFdRT+Nd5U9JZrwO1Tlaz1l4n4/RGlFP4KwUz4zztC8jAQaP0iTaD9zUw+9IRSfPXl30T5hfE6/behVvTAfSD54MA4/MQiKOWpxXL81KAI/7s/pOV1Sxj54xbC8F10uOw/zaz852Dc/LOtRPPfAWLw7FjI/QC0Rv4QyLb11xxe951xSPwlZZjrJ3Ha/HZKHPoRLODq0S1q7lsiMPhA+7z5KimA/RMWFveIG4rysNvM+4IKEvaAuMTBiljwxrXZ/P8PsST5c9R88uVZfvY2Sej/e24o+WmNVPa+TK7yLB3Y/zC05Ox/34LwZcsc8l9N/P5tVrL4LkkI9JLxWvH27cD+Ajg+/BsfSviPT2b5fLxQ/mAw5vMH8IT9WHx6/TQrvPly/xD6kZIO+aJPlPXs1YT8hWnU9mYRUvoeckb3rSnk/F6Eav1WxsD60o7Y+B6EfP+G/CbxI/iK/HK0bP+u68j6ClBc/jNRgPnITML5njUE/ineVPRia8Dtg5Ws9ZeJ+PxK2Tz/3tl8+y6rcvJ+fCj/zM2c/UOLRvHftXj0vqdk+l6g7v4nmQbr5kX0+gC0iP26yrTmXxUS/KsIjP2O40Dn6hs4+ROamvAOgJDurMGo/faI4P0arezyJO4O8PT0xP4A2CL+AyEe9CHbbvOdIWD9MMxI6zdx2vyOShz4WMSE6DPgFvD0pjT6kLvk+DuNgP1yBbb2g+wy9YTDyPuOChL0aHp+ygW1INK12fz918EM+6rREPPDONL0n/3o/uxCIPmx2Uj17I5W8U2Z2P+McDTw6fdu89kPkPJbMfz/yrqm+qT9JPbo/GrxOMXE/f44PvwXH0r4h09m+YS8UP4KETbxyjCE/bykfv2By7T4muMQ+HJ2DviL25T09LWE/KFp1PZqEVL6HnJG96kp5PxihGr9VsbA+sqO2PgmhHz9z5T68m+AhvxBjHj/6oe4+/YwbP9IPXj7AjTW+6EE+P4l3lT1pmvA7a+VrPWTifj+lEV8/UwtRPlMyzrzfEOQ+x6BdP2OJBL214GY9hhb+PqDsQr+WH127Gp9zPuReGj8tF6k5MktIv3duHz+xcNQ5zdrXPkmHo7zDUCE7ghRoP7jmQT81QoQ8EK2ZvAYHJz/q2AG//B4cvXLAXbztYVw/rcsPOdDcdr8pkoc+9eoCOspOF7ymeY0++mwCPzTHYD9xBji9i4I+vTPK8j7igoS9NnTpMsClazOtdn8/PFI7PugpgjxuVMq8YZF7P1c6hD7A6E09mbr5vGvbdj+nM4k89fzUvPNIBj1ovX8/EfGlvvsBUj1/JIq7tdJxP3+OD78Gx9K+I9PZvmAvFD8BNUS8GcAhP6avHr9yLe4+hrvEPrOCg77xx+U9GTFhPzFadT2YhFS+iZyRvepKeT8XoRq/VrGwPrSjtj4HoR8/b6VMvMSRIb8EHR8/XoXtPneaHD8+VF0+4As3vhNbPT+Jd5U9fJrwO2flaz1l4n4/eDZrP5Q5Nj4uvrO8eAu0Pr+aTj/BxzW943B6PfPrFT/RJVi/t6kovWR/Rz5Tsv4+T/eFOVqoXr+Pqfw+kibsOYeq7j5Fl5W8/o0TO7dvYj8S0Uo/LPSLPMERtrxlCxw/SN8Xv8xuO7z9ITm8HgtOP/faDznP3Ha/LJKHPjXsAjoykeW7RriNPmyeBT9aUGA/rwzovKpQfr0JP/Q+34KEvT7ajjKAw4murXZ/P9G6Mz6BI6o8514eOxf4ez9UQIE+PLlHPQwMNL1FI3c/e7rAPJ+g0Lzq+RY9Cqx/P5bPor4OwFg9a1oAOW9Vcj9/jg+/CMfSvh/T2b5hLxQ/XoMjvF5uIj8yDR2/U6vwPijGxD4kL4O+ADblPUg9YT8mWnU9m4RUvoqckb3rSnk/F6Eav1ixsD6zo7Y+CKEfPz2RKbyuViK/J0gdPyBQ8D6f8Bk/Ki9fPsJNM74xnT8/h3eVPYKa8Dtn5Ws9ZOJ+P8ylOz+nVFg+XGLVvLNkJT9ymGE/GXu1vNGtKT3P0PA+rT9Uv7S0ar0x+QQ+JHEKP4/NMTkR5HG/v6CnPk5HADojTQU/vYlsvGZQ6To8hlo/sZBRP3V4ozz/pOm8A8MSP0kZLL/clKo8sENNvBprPT+oxw85z9x2vyyShz4o6wI6NksQu3ryjT5yUwY/+rVfP5rbKbwOMaK99Yf1Pt2ChL0gk0wxwE5SL612fz/Z6TA+CYPVPFjiED1D5ns/kf+APnAWPj2YT2K9Sw13P3oLzzwsp8+8F0QbPd+mfz9iAKK+6WhaPfDIojqadnI/fo4PvwfH0r4h09m+YS8UP4B697s7NSM/tCAbv0+Q8z7p0MQ+mNqCvkqi5D2SSWE/JVp1PZmEVL6LnJG960p5PxahGr9XsbA+saO2PgqhHz8GhtS7AJsjvwgiGj/cBvU+V0oVP0tuYj6CBC2+DmFDP4t3lT3GmfA7aOVrPWXifj/qhfQ+6FlYPmhn1bxBN1o/zPxZPw+sl7zIv/Y8cewFPxo1K78JmAm95SFYPbimPT/d1wQ5ztx2vzOShz7vKQI6eNMUPwk6CLyeXoY6skhQPwGYVj9ImL48zgoTvQgpCz9cTz6/uERZPX/MobxwnCo/m9YPOc/cdr8tkoc+tusCOnDOlDtcPI4+XM4EP3VBXz88g+M7TAnEvT+t9T7dgoS9zrLrMiYAqTGtdn8/oW40Ps5wAD01L5E9RjZ7PyIphD7LZTA9COZ+vYGQdj9bOqg8XHDSvGOfDz06tH8/lDGkvr/VVT2n6uq6LhxyP3+OD78Dx9K+I9PZvmEvFD9x+r67lrojP9LMGb+cifU+NNfEPt2ogr5fS+Q9ylBhPzFadT2ahFS+jJyRvepKeT8XoRq/VLGwPrOjtj4JoR8/LpYqu1e/JL/XIhc/wmn5PuHIED/rmGU+aDEnvlvTRj+Nd5U9QprwO2Xlaz1k4n4/prPSPkMLUD68Nc28PFtjPwv7SD80aKS8xcDQPOJYHj8qOxy/u1cTu112HD0zkEo/TqySONDcdr8tkoc+VSn8OVSSIz8+Dfa6DbRyOTjtRD8v8Vo/c07MPHtpKb3EFgQ/Vy1Lv2QRpD1Knhq92BQaP/98GTlXjnW/TsCQPuY5AjpEmUw8WKaOPj6MAD8OOV8/0KiyPNRG4L2EDfQ+4YKEvRt56DFEqjwxrXZ/P9QROz5qMRQ922bTPSIhej8t9Ig+bm0iPRNkhr2443U//plOPC4d2LyNGfg86MV/P+vYp761pU09y9fguzeBcT9/jg+/BMfSviTT2b5gLxQ/1ArCu4azIz8H3xm/qm71PuPWxD5Vq4K+tk/kPW5QYT8vWnU9moRUvo6ckb3qSnk/F6Eav1SxsD61o7Y+B6EfP/rnRLr0QCW/AsEVP05n+z52rg4/DRVnPh6NJL7KXkg/jXeVPUSa8Dtj5Ws9ZeJ+PwDxwz7W6UQ+JDvCvIFAZz9bJkI/ONIuvJpDSzxhziY/QTYev/6+ijw2iVc9p8JIPzB8ljbP3Ha/MJKHPjm98jldHic/LOjduzPhWjoZ60E/COVjPwsymTyoVha9Y0joPhj4QL/gobs9X1e5vfz1JD9PQmM5FoZovw8v1j4Ho/Y5OwirPA0ajz5CovU+5pNfPwoZBD1O3fK9vVLxPtmChL0AJIyygpHGMa12fz+mYUE+G+giPYZ6AT7IF3k/gVKNPiAsGD00Uoi9okd1P0uzqjvJn9680VTTPBbRfz9VPqu+xV1FPczUPbxT7HA/fo4PvwnH0r4i09m+YS8UPxgu/7uGIiM/u08bvwdK8z73z8Q+GeKCvkqv5D17SGE/Mlp1PZyEVL6LnJG96kp5PxehGr9XsbA+s6O2PgihHz+VoyO768Ykv2QOFz9Yh/k+36kQP9GuZT4oCie+ZupGP493lT38mfA7W+VrPWXifj8/47I+vfQ2Pqp2tLy9ZWs/TeNCPw7nMjqjg1W68v4lP3S4GL9lMgo9Omh5Pa2uTD+2RQu30Nx2vy2Shz6s5vA5cEQoP+ZrmryiURg7ed5APx+Saj+nOog72k8bvDL+zD4TpCm/69aNPZmfLb7n5jk/iD2dOQSzUL8vQhQ/5lvdOYS/7DxOdI8+5KPwPiQfYD9RGRU9Ngf5vXS+7j7TgoS9NEaZsmlfirKtdn8/BjxEPqPdKD1Q0Ao+j594P2VDjz7cLhQ9XlCIvf0BdT/THfc6iezhvIfAwjxu1H8/qMOsvhNzQT10jWC8HKhwP36OD78Fx9K+JNPZvmAvFD8EdSe8/VkiP8E+Hb8qYPA+A8XEPlU4g74ARuU98DthPxladT2XhFS+iJyRvetKeT8XoRq/VbGwPrWjtj4HoR8/XvPPuymmI7+CBRo/BjH1PuMfFT/Ii2I+KcwsvnOCQz+Gd5U9YprwO2Llaz1l4n4/lyy4PoePOD7hC7a80UtqPxPXOz9Q5Aa8mHgRPFbnLT8t496+SetjPaCXHz0Q0GU/oNgPOc/cdr8skoc+busCOs15Nj8/GPK80MtuO6JjMz8NnGo/FcDMuyI+ajxlusw+Gjwlv4skCT1cAmK++P46P/48sTml9kG/SRMnPxLBzTnQDde6IjYsPmrKBT8jkFA/+OLCvUTph73tchE/14KEvcRQATIpbiGxrXZ/P634Mj5pwSY5vTQXOUcPfD8NC4A+9+TiOQvEIzmH3Xc//bwQvpRbormNeye5CW59P/wyV77Zao09NRQhvXR0eT85PAm/6f7ivsuQ6r4Spw0/gSgBPupSIT/ImRG/zWgDPx+YgD4/nNW+JRr4PfNuXT8fG9k99OvQOwRT0rynd34/2wIqv9ZhyT4Qwao+WpQKPxG8QT3dVSS/huATP2GDAD9Co7s+bNYoPnN/h719zmk/NQXvPaklPzuzaTc9q/19P9YhID/fElo+ehrXvCoIQD/8WUw/eCLbvL+JET14xhk/uoQov6YE+zxFWRI+Fws9PxvaDznP3Ha/LJKHPvjrAjqxik4/5CnOvvdaSz2l5ts+BKpMP22VKD5a1YG+SeIEPwF/V7+YUM29mdgjvsh2AT+Csg85z9x2vy2Shz406wI6oumevDlqjD382l0/z6U1P3FRrL0SVK+9kMAxP92ChL0eVn+xWT/QMK12fz/ppzw9y4IMO7gA4Do0un8/PyTqvO+2v7pARFC70+R/P4uf5D37GuY6zUb1Oihmfj8xAeq9kE2lPVLvErzleH0/vr8Wv7hHyr6uAvu+4LoBP+Ugxb7OazM/YCSZvg1KBT9xJ5c+Jn3APQahQ72WGHM/sJfVPXjFd7tw+d68uIF+P1LBLr/XdsA+aqCzPlDtBD9+Rqy+cd43v5/JLT5vvBU/v7ZvPgdGxb4fOg8+F69hP6MM8D2aG+Y7Cec4PVv3fT8khnY/rQUVPgL+krx3nWc+3C6kPuEY171LSxI95c9wP+WR774k3tE8Hx7bPaR8YD99zg85z9x2vyuShz7k6gI6O1R+vzZXVD2xctG79a7PPXtQHTzxer0+FTB2uznPbT/LYtK+rR2evZ8sH77kHmU/FakPOc/cdr8tkoc+H+gCOtzdCr2Vm0E9NEhfP9vwIT8M7rG9dq0GvuoeQj/YgoS9W6KzMVrXVq+tdn8/RhsuPjWQojzKP5U8oi18P2kr1DxNK5m8yNzhvKHFfz/fb949+xmhPEjUWDzIaX4/jo9KPMDtuT3iYQm9T8d+P0ifGb8iGL2+4XjQvpfEFD9/SWW+sUY3P4jsrb4cQBE/mnzSPk2zTT0AFSq+dRllPyTDrD3gZNC90AUyvYuCfT8WXB2/bV+9PsMrrj5vpBs/xFzgvcW5Ob9AHoQ+p+ggP0kW8j5UdhS+IArAPmu3SD/DHfg9jyYtPUmgRD0Rln0/QQphP5+opT7sZiO9EBSyPpQ9VT9B0iu9lI+APQNTDD8qoq6+Kny9PbGxXT6D+mg/EM4POdDcdr8rkoc+WewCOssaej8B9ja+83e0PP+P6j3HXfk+VbuSPn73ML7yhE4/H4qEviCETb5YI5a93CVxPwvNDznQ3Ha/K5KHPsDsAjoLuye9JwQzPUoyYD+rMho/aES9vYWDIb5U60Y/34KEvaA2ky4aloIxrXZ/PxOqiT4pI9Q85uHAPPFodj+r9QI+D0hPvQDzJL2AW30/LKFRPWZtNj1nrYU8QGB/P69EKj1ubcs92n+Evdz4fT9lFhm/gOSmvu4uob5BPSk/RxvPvPSaND8IXcG+12MZPzoy1z5Ihbq9Nm60vY0DZj9i32E9xhBXvtD3gr3dWnk/uLUQv6Jluz6Go6s+XqwoP2xxVz1pCza/qSdIPhteLD+iSxE/v+nLPWeNJT5zF00/RIb8PbWQhD2uE0s9BDB9P1PZVj/Dj+k+QGFmvVK9lD4z+20/W+y6u+/sajwghrw+cVL2vpuKTz6IR6w+FaNIP6nFDznP3Ha/LpKHPtjtAjpJUVQ/Ti6rvlXZKD1MNuQ+hOpNP6IlPD65YKG+WRjwPvFU+76bo0W+BdDHvP5mWT+24A85z9x2vy2Shz627AI6haonvU9/MT1eeGA/8vkXP86/ub23oCC+rbdIP9iChL0m+AkyuBzMMa12fz83QqU+IputPASVwDyjKXI/EqNIPnVbg738tw69b1d6P3YnXLxtX1U9MslAPI2cfz9WtYO8LBzMPYXTmr2w9H0/5nYYv8OdoL4agZa+FbgtP71zAj3HJzQ/TDuvvhYtHz9XULE+ZYRovgccGD2x0mg/A0pCPVxGcL6WKo295e13P/kHEb/FEbs+5v6rPqtlKD/oXJE93DM1v84NHz7EeC8/VQIBPxxLRT7jpdS9deZVP0yG/D21kIQ9thNLPQQwfT/4Gls/p3DqPh8/Z704UG8+JI5rP6FzpLypkEI9KsDGPi6NDr/qkT4+ZamoPi9MPT/t0Q85z9x2vy2Shz4Q7QI64a5bP0Mior7c7B89hvLNPvRTSj9uN0A+oAKXvozMAD/sNxq/q49Vvulaer1YnUQ/mLkPOc/cdr8wkoc+dewCOop5I700/Ds9HmFgP6aUGD9uJ7O9n58cvuaMSD/cgoS9IsfRsoPu/bGtdn8/ug6lPmWPljxMcNM8VzJyPxgGWT4XmIS98yYEvY1/eT8Ieta8cZ5SPZCjITydj38/qI6+vNHjxj0gKJ69t/N9PynxGL+OM6C+I/KWvnpMLT9MiyY9roM0P4sFpL4XmyE/R8OQPmlVjr6UtcI9bsBpPxdKQj1eRnC+lCqNveXtdz/C0hG/tUG6PiPgrD4vtic/oF6bPQDINL8GygM+IS0xP/gq6T7wik0+LTAZvoC3Wj8+Oc89pjoCPbizX7w1iH4/3D9fP/Eg4D5KE129Ch9ZPr9DZz8bAxa9zhuhPQkH1z6lGhq//eUXPg1ioT438Tc/Ab0POc/cdr8skoc+leYCOglzZT9Ao5K+5qMQPelprD6tOEA/hTNQPn+lib5SZhE/4bUhv4QbX75dB6+9wzI9P7jODznP3Ha/LJKHPpHpAjoZaBy9zrZQPfb9Xz/muRs/wiuqvdRGFr5gjEY/2YKEvasSurD1dQKyrXZ/P/J6mz4R1XM8bHTqPF7Fcz8i1Fs+W2aBvS+z+7w4Ynk/4RvKvMLmST1D+BE8wpl/P4/njrxwBsI9g/KbvQ0Qfj8K0hm/s26fvvzBl74AhSw/Q+lLPdaEND+ZLZ2+ZiAjPzKuhz4fDYq+YFu3Pbbjaz8OSkI9X0Zwvpkqjb3l7Xc/XfYSvxsTuT7uI64+5LYmP/X7mz1tujS/2cn/PXRmMT8RZ9U+SW9JPu83B77yqGA/LWa7PXsonTxZGCG9Ba5+P0ZGYT/f+tc+qwlVvTwxWT5OmmE/gGtnvfgy3z2Iruk+4y4bv/8LAD56TZU+BLM6PyPJDznP3Ha/LZKHPkbuAjpofW0/S5+AvoW9/TySgow+SpQwP+FaaT4kqXq+5mQkPyegHL+hqGK+fDzEvRTaQD8t1Q85z9x2vy2Shz4M6wI6bk8Uvdo8az1yiF8/pOkfPyQpn708nQ6+MrJDP96ChL0QKdowHHvTsK12fz94+4w+XqAxPCojAz2T83U/V6RZPiBNeL1WffG8F455P/uajLxj0T09wUoFPMGtfz/0vdq7HdO8PYdHl72UM34/Ffkav3tpnr6Y0pi+J3wrPybXdD2qUzQ/S4SYvro4JD9se4I+sfh2vhypnD0o7G4/DkpCPV9GcL6VKo295e13PzNTFL/Uo7c+FqevPtSAJT+kFZo9Rcw0v0p2Aj75PDE/sofCPrefNj7+tty9TbdmP3U9wz1USsM8uZvxvCmmfj9gAmI/L4bSPgioT73nh2I+6oRbP7xgm70GgQc+QZP7PgItGL9ca+Y92YyKPuKzPz+LzQ85z9x2vyyShz746QI6eu1zP03ZV76k6NQ8kvVdPrvOGz/kCoQ+5eVfvsjCNz/atgu/PBZjvuV8vr1QfU0/DNQPOc/cdr8ukoc+Su4COgtoDL2qZoQ97hpfPyx5JD+Jz5K94XEGvpdmQD/dgoS9+9IvsvB32zCtdn8/S4B3PrZq1TtC4RI9DDx4PwZiVT50M2y9llzovNDWeT++Gdy7UB4wPV0A8DsnwH8/ST3JO/Jctz1hi5G9L1F+PyZGHL9zPp2+NAaavthMKj858Y49EQc0PyZflb74AiU/Hk5+PtFITr4mN3w9ogtyPxBKQj1bRnC+jiqNveXtdz8tyhW/ZBK2Pg1HsT7CLSQ/SRWUPX79NL//Ywg+rdcwP72RsD5qNhk+x6WmvXdObD8lsc49Esz9PHQNcrySin4/S+dhP3Yezz4iTEy9fIhwPmpNVj/yoby9D0kYPiSvBD/ZhRa/1jTXPdT4gj4OmEI/x9wPOc/cdr8tkoc+X+wCOujIeD+fXSq+hguoPOu6KT6vEgM/rhOUPqW9QL5OYEk/Afznvj3lX76roK29MC1cP2DMDznP3Ha/LZKHPtruAjrHgwW9ZnWTPfPCXj88+Sg/5QWGvW7y/L0v9Dw/2oKEvRiw6bKaQ/WxrXZ/Px4MUz7nOhA7JF8jPYhLej8YV1A+YDNgvSZA4LzEJ3o/LISiOw5GIj1D8dI7Ysp/P1pBnzyF87E9xZ6LvaBifj/GmR2/9wicvrU/m769Eik/U5ShPYuxMz+hZJO+C40lP3NKej7ivB++k3E9PS+3dD8KSkI9XUZwvo8qjb3l7Xc/FD0Xv3h+tD5A4rI+VtgiP7LuiD0cTjW/dHcQPi5CMD8E658+ZnbqPTvEZb0V/nA/hqDbPVkrIj22ch47MFJ+Pzc+YT+bB80+mDxKvb+RgD5ARVI/cD/XvSSNJD7Sfwk/L8IWv7euzT3aLXs+JHVDP3nNDznP3Ha/LZKHPu7nAjpLBXw/1IP6vV0adzxQIQA+X8jSPrwpoj5l4R6+zx5XP583ur7dBlm+LE6hvRJWZz9+3w85z9x2vyyShz7i8QI6yRcAvaKDoT22hV4/eQ0tP/nBc711pu69/qY5P9iChL0BCeuyrDlusa12fz8g+i8+CGTnuiYiMz0/8Xs/gCRLPjmAVb08eNm8+HZ6P6AYiDwflBU9MVq1OzzKfz9VgwM9nACtPaAihr2NZn4/VdUevyblmr7cYpy+buonPzS9sD29YjM/pkqSvv7iJT9lGXg+qafhvX0NAj28oXY/JkpCPWBGcL6PKo295e13P5qOGL/ECLM+RFi0Pk+cIT+IxHE9Z7c1v3IlGj4ZgS8/+kqRPgoNnT2pQwu984h0Pycl6D1D3kY9x4ChPP3+fT8iN2A/JfzLPrE0Sb2uJ4k+cmhPP6hj6736ly0+9JkMP9MyGL+xBsg91cJzPhIFQz+b0w850Nx2vyuShz7S7QI6zsx9P52Nrr3/LCw8axvKPfeSpj4GRaw+KyIAvmPzXz8W9Je+4Z1QvnjjnL0BCG4/GsUPOdDcdr8okoc+ReoCOjaQ+LzaQK09umFeP9NiMD/nM1+9gh3jvRnSNj/cgoS9wCkNs8xQt7Gtdn8/bc0RPsc2pbtecEA9URp9P4U3Rj4g9Ey982nUvE2+ej/KzN08njALPW4UmzthwX8/ApkwPV74qD1clIG9iF9+PwPbH7/875m+M1SdvmPxJj8uc7s9PSYzP3LKkb6IESY/0hp3PtRhjr1ra548KL93PwNKQj1dRnC+mSqNveXtdz9Vohm/EdOxPqmJtT5HliA/B/RKPRYsNr/sSSU+dZYuPzyZhT7XHCU9CBKGvFLhdj85p/I9eutnPTSfDj1moH0/hBBfP42uyz4x6Ei9U+aQPhObTT8iV/m9dgs0PspaDj8SHhq/SuzEPXcDbz4l7UE/+74POc/cdr8ukoc+h+gCOnGefj90pnC9YF/tO0x1rj2a1oY++WCyPmxF0r1bymQ/DsiBvpP/SL47L5y9RrNxP/G5DznP3Ha/LpKHPoroAjrSCfS8gVW1PfZQXj9pqDI/UfxQvc1h270i0TQ/3YKEvfKPl7I41bowrXZ/P6yi+D3Jde67roRJPYnJfT/0KkI+vDpHvTZq0bw29no/R0APPUYrBD3FyYg7MLV/P4TYUT2ETKY9Ps18vbdTfj+ejSC/+0aZvt74nb6lRSY/WHbBPUYCMz89o5G+ViUmP1LTdj6rdCO9rJorPC06eD8FSkI9XkZwvpEqjb3l7Xc/blwav8X/sD6vV7Y+buMfP74TJD2olja/PYIxPkSPLT/cqHs+rk4rPCy3h7vCIXg/9db5PRvffz1zYzo9BVF9P0kZXj9/x8s+1ABJvUaVlj6MsEw/trkAviAUOD7zHw8/Mcsbvx9zwz1CcGw+5c1APwm3DznP3Ha/K5KHPpDqAjo04H4/Pk03vS/OtDtXBKg9U4BsPvZAtT61t7m9j9dmP/2Qbr6ss0O+NlycvShRcz+Rww85z9x2vy2Shz5T6QI6QHryvOZeuD1rTF4/E4QzP6SuS72hhdi9/Qo0P9mChL2ac4ixPCpyMa12fz8T2ec9Bt8EvHHSTD0CBn4/BElAPrwSRb2OhdC8SQ97P6zbHD0VkAE99FSCO5iufz/Xm189W1qlPVVPer3sTH4/C9Agv8UHmb4aNp6+ZwUmP5BAwz0h9zI/9J+Rvq8pJj+t1nY+OYrmvHUm5TsSV3g/EUpCPWNGcL6TKo295e13PxehGr9XsbA+tKO2PgehHz9MhQ09zs42v5VVOj6d0yw/LgJ2PleMg7tJO4I6EIB4P0aG/D2ykIQ9xhNLPQQwfT8jr10/7+bLPtwfSb1m15g+eHBMP3QLAr69hTk+mUoPPx6EHL/GB8M9LaVrPi5JQD/Zzw85z9x2vyyShz6y7gI6veN+Pw84Kb336aY702iqPVOvZD619bU+BvOzvTNEZz/zMmq+FsZBvrNOnL3NrXM/SMYPOc/cdr8rkoc+PukCOkB68rzmXrg9a0xePxOEMz+krku9oYXYvf0KND/ZgoS9mnOIsTwqcjGtdn8/E9nnPQbfBLxx0kw9AgZ+PwRJQD68EkW9joXQvEkPez+s2xw9FZABPfRUgjuYrn8/15tfPVtapT1VT3q97Ex+PwvQIL/FB5m+GjaevmcFJj+QQMM9IfcyP/Sfkb6vKSY/rdZ2PjmK5rx1JuU7Eld4PxFKQj1jRnC+kyqNveXtdz8XoRq/V7GwPrSjtj4HoR8/TIUNPc7ONr+VVTo+ndMsPy4Cdj5XjIO7STuCOhCAeD9Ghvw9spCEPcYTSz0EMH0/I69dP+/myz7cH0m9ZteYPnhwTD90CwK+vYU5PplKDz8ehBy/xgfDPS2laz4uSUA/2c8POc/cdr8skoc+su4COr3jfj8POCm99+mmO9Noqj1Tr2Q+tfW1Pgbzs70zRGc/8zJqvhbGQb6zTpy9za1zP0jGDznP3Ha/K5KHPj7pAjqYedG8kCa3PWo7Xj9yVzM/C2+AvT47072TDDQ/3IKEvSLLdLKf5MaxrXZ/P9Pp6D1I+h+8jFIdPfwifj+1HEE+XZpBvZu3mryQEXs/GjQaPRah/jzb2946wrF/P3U9dz0b4KA9fsKHvcMsfj/QpCC/7zCZvkMOnr48LyY/RZi3Pa9OMz8fPJC+B04mP1IzXz5Ru/q8JhjgOzK3eT/6SUI9XEZwvo8qjb3l7Xc/F6Eav1WxsD6zo7Y+CaEfP1wQJD3UlTa/foY+PsqyLD+WGX0+30NouQ8faziYDng/SIb8PbWQhD22E0s9BDB9P9BeYT/aPcE+8Zs+vd0kkT47bEg/T+cOvg5EQj6rahM/bjUcv5eBqj0xzWU+1VZBPxvLDznP3Ha/LJKHPobqAjr6734/pU5CvQ6pvzv7oZ49zgJUPoNstj7gfqa9rlJoP01cX75onUm+9JmhvQDdcz/Dwg85z9x2vyuShz7a6AI6QkypvOIztT3mLF4/uTMzP74Imr0ECsK9Ni00P96ChL3QC0GyLXgksq12fz/O7Ok9WLw/vISvyjxhOn4/RwpCPtGAPb3CWDy8vhB7P3trFz2By/k8j8E7urG0fz+B5Ig9veKbPatQk709BH4/6DYgvzSZmb7xqJ2+M5kmP4DXrz3BcjM/mlCRvmkMJj/qz0g+YUsJvSLH2ztp4Ho/E0pCPWJGcL6LKo295e13PxehGr9WsbA+taO2PgehHz9Y5ik9ZoY2v2tNQD7xnSw/vHeHPhHqlTvJoKS6r992P0yG/D20kIQ9shNLPQQwfT9URmU/nya0PlmyMb3mlIk+2aNDPzwgHr4VeUs+nAUYP3NZG785e5k9EWZdPnrcQj++xw850Nx2vyuShz4g7AI6CnV+Pwdojr2Edww8mausPRCeYT4bwbQ+9P+vvfC8Zz+/+WO+Mq1Ovlhpor2RUnM/AcgPOc/cdr8skoc+N+oCOoCSgbyRH7M9DyheP2QnMz9lDKy9phunvTFkND/dgoS9mF2OsgKJCbWtdn8/m6jqPWBPXrx42jw870V+P0TmQj4FjTm9y4uZu7sMez+dDBU9z5P1PCppN7vetn8/KyyVPcxYlz0JpJ29wdp9P/WiH7+9JJq+hSCdvv4mJz/3yK89vE4zP0GblL7beCU/oiM4PnkjFb2QPto7CaZ7PwNKQj1hRnC+lSqNveXtdz8XoRq/VbGwPrSjtj4IoR8/TqIZPXOvNr92cT8+CJEsP/5Ckz5k8xs8y2Y7u10rdT9Nhvw9t5CEPbQTSz0EMH0/t55oP8cwpz6p6SS9OpmDPpj2Pj+Dviy+RhRTPlREHD+9Chq/txSVPSvwUz4umkQ/3M0POc/cdr8rkoc+Zu4COgxBfT9KXtO9R31QPDcY0j02e4U+58iwPgLJzb2ZXGU/4zl3vvsMT75eqJ696SlyP8zGDznP3Ha/K5KHPhnpAjp6uUO8NKCxPf8rXj+mOzM/eQG0vWDCiL07lzQ/24KEvXkiuDIVJrkwrXZ/P3gD6z1BpnW8wLaoOptHfj9FfUM+A5A2veJDDzlQCHs/dJwTPSX48jzDgIW7Cbh/P3L7nT3FVZQ97pukvdm6fT/WBR+/57eavpuPnL6BvCc/LLy1PfDwMj9ubpm+WqokP7WtMT4R7B+9x5fhO5jpez//SUI9XEZwvo8qjb3l7Xc/FaEav1SxsD64o7Y+CaEfP0Hy8TzT/za/bpY8PiyILD+CeJ8+bIxiPHuJlLvCPHM/SIb8PbaQhD22E0s9BDB9Pw/laj89CJ0+ruQavdMXgD7tajs/2N83vqJUWD6mSR8/1bAYvymanD1we0s+Ex5GP3jODznP3Ha/LJKHPtnrAjqLjHs/JHIMvl+Iijx/7/09sNqdPuaoqz4s5++93+thP7iVh75J30q+GA+avWLTcD89vw85z9x2vyuShz755gI6pSMkvBkwsT39MF4/+HMzP3n3sL1MCF698rE0P9yChL02SpKxmwcvs612fz8B3+o9jN1/vNF8XbsvR34/CJtDPhJnNb1sg846oAd7P16XEz0M7/I8pBKGuw24fz+ryKA9svOTPf4fpr3AsH0/BH0evzg3m75mEZy+zD0oPzAzvj1udjI/V9OevhbBIz/0xTg+zKAnvao89juOkns/AUpCPWNGcL6LKo295e13PxehGr9WsbA+t6O2PgehHz8JjKQ8uVo3vxeAOD4qhSw/y66pPs2Chzw0b767o31xP0qG/D20kIQ9sRNLPQQwfT/9q2s/f4OYPpxvFr1A2n8+0Sc6P4qnPL4cQFs+nCogP7jYF79nEq09iQNGPp/lRj/lzA85z9x2vyyShz6+6gI6kNl5P7/fJr7SmaQ8rKYSPpOksz6GvKY+xcwGvpM4Xj/Q0JK+4KxDvscrlr0+lm8/pMUPOc/cdr8rkoc+e+YCOjxAMbzg1rE9pi5eP+vIMz+wjaK9avdBvfmzND/agoS9zJuCMT/iTbCtdn8/8GDqPX3Sd7w9tha530l+PycvQz6Loja9qwSGugcMez858hQ9C2T1PO9jPbv0tn8/lQCcPfJelj09cKG9GsN9P08mHr+Ch5u+ZsGbvlCPKD84/Mc9RfcxP6d6o75D9yI/UmlKPn2WKb1y6Qg8Qbd6Pw9KQj1dRnC+liqNveXtdz8XoRq/WLGwPrKjtj4IoR8/mfU/POemN7+KUjM+bpgsP1WOrz5134o8MMvKu7tvcD9Nhvw9t5CEPbITSz0EMH0/k6NqP9ytmz78jhm93ZiDPp/iOz/sKDm+2KtbPvdaHj/S3he/2R7DPUneRD57oUY/jsgPOc/cdr8skoc+NesCOrbAeD9nYzO+0/GwPB3PID7rh8M+ZU2jPrHHEb64DFs/fK2bvlEmO77Z05K9/6RuP0DIDznP3Ha/K5KHPlvqAjq+X2W8vAyzPWImXj/PHDQ/1m+LvaD4QL3DrjQ/44KEvZLWCDO0SLe0rXZ/PxOl6T0jCWG8X+IcPN9Kfj/AZEI+Vrg5vfva2bsjEns/7TUXPTlt+Txss2u65bR/PxShkT2Hm5o9rVKYvRzofT/9Hh6/RI6bvqC6m74vlig/NDjSPUqMMT+bP6a++YQiPwiyYT6vpSO9+QgUPPh7eT8OSkI9YUZwvo0qjb3l7Xc/F6Eav1exsD6yo7Y+B6EfPyz+tDvu2ze/lEYuPt63LD+YBK8+Pd9yPBO3sLuDi3A/T4b8PbGQhD3FE0s9BDB9P54MaD8zLaU+Nu0ivW0Nij78zD8/8uYuvrwAWT4wkxo/aIUYv5eS2j0yqEc+5ZJFP23MDznQ3Ha/K5KHPvzuAjprmng/FOMwvil6rjw5Mic+lIXLPiYqoj40/Be+bitZP/IBob50tTK+XDeQvXIwbj8rxw85z9x2vyyShz7D6AI63kaZvHlTtD1IIV4/PE80P+rgYL34Alm9eKw0P9yChL2gucgxhzALsa12fz89xeg9XuZBvPUbvDxRQX4/onFBPtLBPb1FGGO86RV7P1HoGT3IHv48B1C9Oheyfz+8YYQ9/5GfPUjzjL0ZE34/tW0ev25Fm75GA5y+N0woP6dF2z24TDE/mIemvhqIIj+OzXk+RTkWvbRCFzyyE3g/HEpCPV5GcL6NKo295e13PxehGr9WsbA+sqO2PgehHz+fpBE7ivY3v6ezKj7f1Sw/No2oPnlrKjxLsG27xrZxP0uG/D23kIQ9wxNLPQQwfT8SXWQ/CUuyPkHdL7382ZE+N7lEP191IL4Eo1I+d9gVP29tGb+aN+89wMRNPtcZRD9WzQ85z9x2vyuShz6b7QI6Q3R5P/YeIL6U8J08mwokPpXEyT6YuKM+bAoYvs5IWT8kkaG+Y8orvinbjr3lbG4/yckPOc/cdr8skoc+9eoCOrHbw7zrhbU9RCdeP7NTND8pMjC9g0mCvXekND/bgoS9lvAIMckUDrGtdn8/TNbnPSkJIbx5Xhg95Sl+P7KKQD6x5UG9eMGtvDsVez85iRw95EoBPXuicjv+rn8/3+ttPfxBpD1hi4G9+jl+P4v1Hr8hx5q+lICcvu/LJz8yaeA94UgxP0aDpL6O8yI/fvyGPpSZBb06JRI8eMp2PwxKQj1iRnC+jSqNveXtdz8XoRq/WLGwPrSjtj4GoR8/BRk3O+bwN79bPik+rPIsP45Anj6+25o7H1fJuh52cz9Rhvw9sJCEPbwTSz0EMH0/ZUVgPwTrvz7HTT29Xn+ZPqOOST+D0hC+jw9JPpcqET/RUxq/fpn8PU94Vj4ui0I/JskPOdDcdr8rkoc+cuwCOkXiej9vcAW+FZ+DPMwFGT5Gab8+KUunPs0ZEr5nMVs/TYWdvuw0KL4sco69rENvPxzFDznP3Ha/K5KHPnrnAjp8kem8VLy2PVY4Xj8uLzQ/+EESvcndnr0giDQ/3oKEvQQvIrIAgAMsrXZ/PzYP5z3Z9QS8noNKPboKfj973D8+8lRFvagf37wiEXs/rpEePaH7Aj3F+LE7Xax/PxEeWD0fyqc9nNBwvS5Wfj8qlh+/wzCavroUnb40Myc/vPfePe6MMT8zcKC+8LQjP5O+jD4WW+68B1wIPAYEdj8ISkI9W0Zwvowqjb3l7Xc/F6Eav1axsD61o7Y+B6EfP5UzBjwmwze/H5YqPlALLT9FSpI+p/JPuhg+dznvU3U/S4b8PbSQhD22E0s9BDB9Pym/XD9VKss+0WVIvYoinz4sVk0/MDYDvjFWPj5ciQ0/1yYbvzfb/T0TmWA+oiRBP3PHDznQ3Ha/K5KHPqbsAjr1YXw/MuXMvbcaSjzr/wg+kbuuPhnMqz5+Fwe+mDleP82ilb6x2Cm+A8OOvYpzcD9Pxw85z9x2vyyShz5h6gI61NwAvVzstz2mS14/hvUzP+ldDb0f0ru9TFY0P9+ChL1+OCkykoPcsa12fz/NtOY9izPou7sLaT1a8n0/bYw/PglSR71Y8fm8Eg17P054Hz35uAM9hO/KOyKrfz8hokw98mSpPe+zZ73kY34/ni8gvxigmb43op2+N6AmP3px2D1eATI/be6avkWsJD+8How+wufdvDer/DsCH3Y/CEpCPWFGcL6UKo295e13PxehGr9WsbA+taO2PgehHz8R6Is8VHU3v1mbLj7WEi0/cueGPqBgmLsTcqY6aPN2P02G/D28kIQ9pBNLPQQwfT8hy1o/mcDRPijlTr01PKE+f1JPP3eq9b3BLTY+mcULP0/cG780UPI9A2ZpPjsmQD9xyA850Nx2vyuShz567AI6j559P7Pukb3S8Q88erLsPcL6mT6vPrA+c4DwvX+yYT9W+Iq+7iUwvkbZkL3FvnE/f8cPOc/cdr8rkoc+jukCOhRLAr2mmrg9ClReP2a5Mz93DyK9AHjQvRQmND/dgoS9wld/saxyxzGtdn8/+wLnPZu16LtFY2k96/B9P/G2Pz4SMke9JvzzvJoMez+3zh49wy0DPUiSuDsLrH8/2NBPPXx0qD1wimu9R2B+P5WiIL8LM5m+NQyevmUxJj/53M49loEyPxKDlb63kiU/taSFPiHk27w37e07zAV3PxJKQj1cRnC+hyqNveXtdz8XoRq/VrGwPrWjtj4HoR8/FQnZPCYeN78DZjQ+PPwsP52/fD5HP7u738O+OicTeD9Ohvw9r5CEPcETSz0EMH0/FTNbP4nl0T6LCU+9A9KePqfvTj/2K/W9VYw0Pu58DD/nWBy/t/zcPZFJbT6V2z8/V8cPOc/cdr8skoc+rewCOjBzfj+f2E292grLO/+1xz11XoQ+bcmzPtTyz72X6GQ/RJl+vhnFOL7uuJW9kOZyP/bDDznP3Ha/K5KHPi3pAjpAevK85l64PWtMXj8ThDM/pK5LvaGF2L39CjQ/2YKEvZpziLE8KnIxrXZ/PxPZ5z0G3wS8cdJMPQIGfj8ESUA+vBJFvY6F0LxJD3s/rNscPRWQAT30VII7mK5/P9ebXz1bWqU9VU96vexMfj8L0CC/xQeZvho2nr5nBSY/kEDDPSH3Mj/0n5G+rykmP63Wdj45iua8dSblOxJXeD8RSkI9Y0ZwvpMqjb3l7Xc/F6Eav1exsD60o7Y+B6EfP0yFDT3Ozja/lVU6Pp3TLD8uAnY+V4yDu0k7gjoQgHg/Rob8PbKQhD3GE0s9BDB9PyOvXT/v5ss+3B9JvWbXmD54cEw/dAsCvr2FOT6ZSg8/HoQcv8YHwz0tpWs+LklAP9nPDznP3Ha/LJKHPrLuAjq9434/DzgpvffppjvTaKo9U69kPrX1tT4G87O9M0RnP/Myar4WxkG+s06cvc2tcz9Ixg85z9x2vyuShz4+6QI6IFvbvFbwuD0iNm0/fspDPwvQer01KOe96Z4hP+CChL08ywUzOiO7Ma12fz97pKQ9iobwu17FZD16w34/+8AePjmJPr2Flgi94Hp8P7Iukj2TEAE9fPEGPPw1fz8m5uY9r92nPY1Vjr0v4Hw/DNAgv8QHmb4bNp6+ZgUmPxBGrj2caDM/vR6Tviq4JT8QJo0+sw1vvaJkiTyZlnU/CkpCPWBGcL6XKo295e13PxehGr9YsbA+taO2PgahHz+vDH889zo3v+DsbD4Poyg/Fy2wPht4wTyM2g28+UdwP1GG/D2zkIQ9oxNLPQQwfT9nIW8/2ddpPmao5rzCwYs+KolGPrSfrr6gqZM9d8BqP9MdRL6dz5A+JorUPZshbz8hHok5GfhcvwlDAT/JYuo5vid+P6MLvb1MeDo82sGaPRKeOT6X3bU+lD2Qve4Raj/cz8i+XEfOvV+xBb5zrGc/wwGCOVjGYL+bDPU+KGvuOQUwELvfdyo+pd8IP/cnUD/AR8G9ZP+JvZIIEj/YgoS9OmnLMWDJBTKtdn8/ZUq9PZdO77ZuX606aud+P+PgLD7S6RW6WlXruURTfD8tuGa9g9+1OUOVJTfyl38/X7XgPcf9fz3hv0y91aB9P3QgAb8gDO++eznbvnY0Fj+j3mW8B5gxPz9D3b6SdRM/zwwsPt9Dkb4PFr09JIZwPx7kSz0pxWi+DxqKvYpfeD9duym/JubIPmf6qj4ABws/1CXvvNvYOL8JPE8+ZDIpP+0Utz6HHQw9EAJXvMTjbj8f6/k9YWYRPdiyTj1pmH0/hxcjP4uTXT7pjtq8RUQ9P7LlST8cwwe9AhMlPQDUHD/44Sa/K1cUPb0cED4GiD4/8ZMSOYSBdr9kJIo+iLsCOnJbUD9+/sq+njpIPWYC2D6xPEo/tW0uPpQKgb4lRwg/u91Vv9TZzb25ISK+IEIEPzcdEjkqjHa/TtiJPprAAjpYIAU7el0zPufJ3D7j7Fk/iKLLvX/UdL1wAQM/3IKEvY0zNDFGcZ6wrXZ/P2IB/j3f3xs5qAg+Of4Ffj+T4Ew+uyvQOdWlSTnk0no/PRG5vaYYl7nefUW53/N+PxDGAb0t1Yc9tc00vawOfz/y6vy+jwL2vqEg4r68EhM/EnfwPb8gJT9PSQi/1hQJP6m1GT5TLd2+8iX6PeCAYT/o5nM9GCNIvgoIer2pHHo/UOMpv7+eyD75r6o+2QYLPwqbOTw2pDS/ssuyPpfPHT91Drw+K/EXPi2vc70lkGo/d7fvPQcucjusgzk9WPl9Py608D70tVI+H9fPvIKfWz9A11w/Yw2HOzVg57vPdgE/6FElv1pMDDznwVA+Ulo8P3fWDznP3Ha/LJKHPi7sAjpPWDw/hiioviLeJT17Rxc/PzFkP0HniT3DfRC+8dPZPs9IYb8RDNQ8TfhBvi6Z3j4p60U78K12vzLjiD6uAKg6gmKNO6oXMz4x4PY+/rJdP1Mpz70Gsmi9ewb5PuSChL1h8vuwblfZMa12fz+OtSM+a6QjOYv3IjkOtXw/xBFxPnKO3TmvRy85CM54P7NlAb7jJ5+5ApgwuafyfT9F5HG9sNKGPR24O70Uun4/YrD7vom1974vdea+3TERP/ZTcD4SsBo/naIOv2HdBD8E/WY+HTv+vlkMJD7RnlI/O3SePaWcBb4BQUe9FLt8PzyJKb9ydMY+IYGqPp1IDD9T1sM9SHopv5LL+z64sw4/34G4PnGubz44WsC95udlP0Qa4T17+Mc8vibrPBtEfj/EPP4+24hYPrmV1bwuaVc/9X1VPycgLrwkOoI8Wi8NPyrwJb8W4U27u21TPvahOz/m1g850Nx2vyuShz6N7AI6c2k8PyNepr7+GSQ9n7IXP831Wz9E4Lk9m4knvlLM8z5pt12/RPfUPErlL76h/+8+7ayaO7WRdr+Iqok+g4PjOjAPtzvunC0+Bg8UP9QGXj+kd8+9RppnvQHb9z7egoS9dvOosWZgUjCtdn8/mfc/PhVkKTm53Aw5F3Z7P/Zthj7PZ+c5gLYZOcAEdz+0zh2+6gWluQibH7kY8Xw/xVpsvQJMhj2vvUO9Wbp+PymN/L4f8va+iKrpvnnbDz852pc+RsAUP6coD78j9QI/r5KjPsx9AL/EIkk+RIVHP2XowT2pkGC9COwQvUtNfj/D/Si/bSLDPgk+qj4gLA4/p+svPp05Hb94nxQ/vJYBPyRdtT4KpZI+7V/rvSj9YT83+NU9PNSPPSiqITxq830/QPsWP5k9Vz4AT9S8g4BHP1jSQj9ttiO97RVAPbFSJT/WuCW/hR4Au/26ND4n0T0/ptUPOdDcdr8rkoc+iewCOv0zRz/gPZu+eiAZPYp9DD+MIUg/AjEJPuYcOL5e9RQ/NjpWv3ojyDzImBC+9UMHPyzuGDs3uXa/05KIPrXHjzoBack76pkkPnpWLj9kL1w/H7/Nvc+pbb2CV/4+2YKEvTu4T7F7qZgxrXZ/P0wRSD6d+Co5XlgGOfwQez8xaIo+1yHqOXZNEzkDeHY///QlvpqoprlWmxq5l518PzB45bxjQYg9tYlHvQIHfz+xxP6+YO70vso17L6isg4/NP6VPqLSEz/cahK/Ce0APxR6wT6e7PC+bpVOPnZ7RT/pO9Y9eSsAu0Sv3LxogH4/L0oov6Lpvj7i8Kk+I4IQP8jRPj5kihi/GTAdP+lA9z7p37Q+j1mWPmBS8b0hYWE/K3/RPUvnyz0jI6y53WB9P4/cMT/tNUY+oILDvG85MT9u2yY/+pOHvZMTaj0l20A/RkggvxD+KjlEGxs+ns9DP1DVDznQ3Ha/KZKHPjjsAjo3H1Y/TAGKvgIgCD0mwfM+IpwrP/GnOT54FzK+hb4yPxpMS78xHpQ8FYz3vbJnGD8HlXo5Ldt2vxCehz76Owo6yurKO5xKGT4ObUU/0OtYP1uyyr3N7He9a6kEP9uChL3QMjGxd0bIMa12fz+1Nz0+CtEoOccPDzlul3s/QhSFPqxz5jk91hs5hzN3P84KG776eKS5BEwhuXMMfT+Au5081j6NPad3Rb1hC38/4GwBv+c78b61Eu2+lBMOPwrjdz6d7BU/g9wYv3TO+z4gR8Y+jqbXviNoND6/DU0/GhvZPcjr0DsFU9K8p3d+P3J4J7/9DLo+GqOpPn0cEz8rTRw+iUwYv0vKIj8oR+8+xCC3PlBUhD7PZdS96i9kP9cs0j1VkMc9z/NNOmtsfT+FcUo/JqUtPp1Hq7zUdhY/h2kDP1jSsb2v7VU9FClaPzVEFr8D9rc6JncIPkhuTD+91g85z9x2vyuShz5E7AI6wu1kP1iCar6OUOc8UFnEPnJHCD+SDmg+WvkZvis5TT96kD2/3rUAPMna5714lCk/N78POc/cdr8tkoc+gekCOuuYwDuGuQw+/oRWPwPGVD8k0sa9ixaCvY43Cz/hgoS9nhKIMczIBjCtdn8/QEcmPtUxJDkgJiE5N5p8PxKZcz7EdN45EVMtOZ6meD+c+gO+HLKfuaUNL7lk3X0/RuCJPe8MlT08ujy9Lnd+P53hBL9mlOq+46/qvjWpDj/x7S0+QmMYP08fIL8PLvM+SLLEPoM0uL6k/BA+z6FWPxsb2T1s69A77VLSvKd3fj+rkya/vtK0PmRcqT5vzxU/dl+1PbnCGr87aCU/eTHqPpBmuj7UAEg+YYKgvd1DaD9J39Q99M2xPT81tzsto30/dm1eP36wEz53rZG8NU7yPlb2tj63C9G9ueQgPZ1zbT/pQAm/GC/rOsOj9j2L4lU/ndcPOc/cdr8skoc+/esCOs0ccT/72jy+aEi6PBhbjz5e8cE+OumIPsHs672D5GA/01QuvzG0FrtJEeq9sis5P2HHDznP3Ha/LZKHPsrqAjooya475bP/PVDKXz+BNFA/WY3CvbdjiL369RE/1YKEvVLjwLFfzUOwrXZ/PwtPBz44qB05YxI4OVjBfT+PE1U+IULTOSzQQzl/ZXo/J77JvfL3mLkI3EC5QcF+P+SD0D38cJ899dkqvfupfT9HOQm//vXhvja95b7uCBA/9imfPZBsGz+pIyW/ezPqPo+yvj5i0o6+sgTNPQYkYT8cG9k9duvQO/ZS0rynd34/ZKglv0CFrz4WIqk+eHIYP0799DspJB+/qhwjP+Y+6T76N70+eyTqPVjoO73Hxms/XBbZPXzTkT2haFA8JeJ9PxP8az8R2Ps9u2l4vAQOvD6hUF8+t3nkvaB7zTwSHng/kuT5vuzRLDuPz+Q9OJldP+7UDznQ3Ha/KZKHPn/sAjoI/Hg/6VgTvhNXkTzeHzo+hr11PjWrmT4KP6C9OH5rP8R1IL/Alj688g36ve37RD/Tug85z9x2vy2Shz6Z6gI62V+ZO+og5z1TDmE/F6ZLP2dLvr35RI6930AYP9iChL16HTExhJpqMK12fz974Mg91foVOeRyUDn+w34/3Z4yPksaxjl/fls5QBN8P7DEg70VBpG58PtTuTV4fz9Todw9kqurPZ5IDL3Jc30/EOENv1tx2L61F9++uccRP1f5yLxiKh8/BMokv6gZ5D5ZxrQ+6s05vgR7aj3agWo/GRvZPTXr0DvtUtK8p3d+P4zEJL/ycqo+s/aoPsPgGj+s1pm9wGMkvw1aGz8rtuw+9Je+PgyX2Dxc0i28Wn1tP91e3j2vMVk9Wf6sPBERfj9Z+3A/Y4PuPZVDa7wnAaI+hDc+PvBq572qILA8otB5P6CC9r5rQAA8E1DZPTa3Xj/A1g85z9x2vyuShz457AI6B9V7P60mBr7YUoQ8x8L5ParVQD6MZ6M+fNiEvaAxbT+Vcxu/+vq+vKIUCb7LZkg/IcYPOc/cdr8tkoc+6eoCOq3cgztoaNE9GtBgP6aDRz9jbrq9ukuTveihHT/YgoS9IcMOMcC5byytdn8/9cGDPQUfDjk262Y5PHh/P5VhED6firg5IENxOUpxfT8P//m8gciIuYHnZbl54X8/02ChPb2Ltz3TX8C8eBl+P5FNEr86Gs++d8LXvmSMEz+SLve95zcjPxpxHr+BmuI+cDmoPis9oL1WkZ88m+dwPx4b2T2S69A77FLSvKd3fj9G9yO/o+2lPhTaqD78+Bw/oi0VvjttKb+ilw8/lnvzPt1Ovj67aGq9+R68PEsibT81GuQ9TikOPSsn8zxwI34/uYxzP/uG6j0jVWe8Rz+SPlz+PT60gOa9QjWvPObWeT8QZ/m+RUVePCeWzz1ZCV4/NNUPOc/cdr8rkoc+DuwCOrUifT9+GgG+m7B+PKkpoD3mbCc+6uOqPjRFcb3aLm0/DRsZvxAoDb1yqBS+MpVJP/6/DznP3Ha/LZKHPovqAjopr2I7YR3APSaoYD8WLkQ/yFC3vdUnl71fwyE/24KEvbppfDHOEzywrXZ/P96VDz2mCgc5QxV5ObjXfz9DNOU9pFCsOZptgTlHZH4/dtydutdTgbkRpXS58/9/P4BnIT0orb89irxKvCyofj86ABa/zQnHvqfo0L4jERU/Aq1Ivl3iJj/NgRS/QgnlPkOEmz6Em3Q8YvYMvHbdcz8bG9k9fOvQO+VS0rynd34/ilAjv31Joj7Pyag+npweP/odSb4Mby2/tOQCP4tc+z4F47w+XrMBvsotUD3xXGs/s3XpPa/amDy/pBg9fRt+P9dtdT/GNec9eQ9kvKJ0hT6ehTw+dO7lvUddrTwo63k/yWr7volQkzzBgcc9LZBdP9nWDznP3Ha/K5KHPpnsAjoV4X0/PXf2vcIbczxboS09hWcPPhBIsT4/e1a9NBhtP6DFFr/z7S+9aDgevsjGSj/LxQ85z9x2vyyShz556QI6KwlJO3C4tD13kmA/AftBP6JCtb1BnZm99GQkP92ChL1KBEAxcjyPsK12fz/ELGw8cd8BOSGIgjkx+X8/ZiO7PXF7ozmDO4c50+1+P2VDnzxxyHe5gI1+uZzzfz+crZU7fKrDPUi9brsX034/kIcYv8pdwb5o08u+cR8WP2JNeL4PdSk/QmALv7a76D55v5E+c6+mPUuAz7zAb3Q/HRvZPZXr0DvnUtK8p3d+P6bgIr+r258+UsKoPpuuHz9IMGe+dvovv7vL8T4E4gA/dk67PlW9Mb5spI491GRpP7Jz7T0sO+47/N8uPRsIfj+qk3Y/e/TkPRPWYbyL8Hk+ePs6Psei5b1HrKs8Cv95P5Ce/L7yoKo8WPzBPQpIXT//1A85z9x2vyuShz7+6wI6ojl+P/YV7L2r3mg8OD2UPGGo+T0tyrU+9o4/vXb5bD+p6BS/9L1FvZDAJL5Pv0s/jsYPOc/cdr8tkoc+huoCOk17PztzmrA9kItgPzUxQT8QhrS9rHqavetRJT/fgoS9jTiOrnNaX7Ctdn8/khfXO42u/zhLwIQ5lv5/P9Qeqz26G6A5rlWJOdQafz94kN88sKRzuXwhgbmX538/P6ZEvJq3xD3PeQc4O8x+Pwl5Gb8ZNr++MNXJvjSGFj8YT4S+/GkqP96GB7/Mh+o+vOONPmI72j2HeP2821N0PyMb2T3n69A731LSvKd3fj+otyK/kPiePkDAqD6BESA/hBZxvjXgML8q3Ok+4SwCPzKYuj6BdUO+ydycPbuBaD8fBe89CCc/O71pNz2r/X0/h/h2P9og5D1aBWG8LdVzPgRVOj6Ei+W9sfyqPEIHej/DCP2+s/myPGnuvz03L10/atcPOc/cdr8skoc+DuwCOkBSfj+ypee93H1kPOMDFjzXy+o9gX+3Pp/mNb2S6Ww/2yYUv0NeTb2nLCe+YSVMP1HCDznP3Ha/LZKHPgfqAjplJ5M8LXG0PAY6Uz/XlyE/+X6kvcEAnb1DgkQ/1YKEvTr/j7FM3W2xrXZ/P3WlUD5zd+U6nYOcPNiUej+Pc+49t5GLO4lRnTyCNX4/4EiDPZeD1rs/EZe8o2x/Pwaj5DxF17E9Hv3VOdDufj/e1Am/U6Luvpv6y76Z/BM/9SeLPkWACj+LRSq/8MjfPoVBQT+uRnG+H2LMPu2K7T7DF9A9oVtiPEIker2QK34/+bwgv1QIoT7ryKY+SA4iP/f8ND5xCBC/jDovP8lv2z5T0lo/CWb1PVOGaL7L7+Y+GQXvPTYmPzvCaTc9q/19PyUDfD/V8dw9Te9ZvAmBDT4TeLo+qtHCvUFBGT1a+mw/QyIYv7MqRT0dsbM9kUpMP+zYDznP3Ha/LJKHPqHrAjrIK3i/2IxKPn/Kx7yHpBI+GrhtPj8poz4Bh6W9+VlqP7/aIb+zz2C9IiBMvtolPz97yQ85z9x2vyyShz4O6wI6SfGSPNEOsjx2OlM/iZ4hP+MRpb1mfZ29RHlEP9+ChL2osOyxhqQBsa12fz8eelA+VyG8Opr9mzw3l3o/RADuPQkfUTuqkp08azd+Pw6ygz0Gjb67WKaXvABsfz8PV+Q8UfWyPTuwZTnB634/39QJv1Si7r6Z+su+mvwTP9X2ij6Kwwo/3N4pv6l44D4fAEU/DNVjvq5yzz7NmeE+yRfQPWVbYjxFJHq9kCt+P/q8IL9SCKE+68imPkkOIj+xlTQ+oCoQv0QMLz/1vts+e9ZaPxsk9T3VR2i+KPTmPkYg7z1ldIw7/D44PVf8fT++A3w/mPDcPR3uWbxkcA0+woS6Ps3Lwr0ZSBk96vdsP3czGL/RpEM9vY+zPa0/TD962Q85z9x2vy2Shz4S7AI66Sp4v8WbSj422ce8MKcSPg10bT73MKM+3VylvWddaj8g1CG/HeJhvbphTL7SJT8/MrkPOc/cdr8tkoc+xuoCOrF3kTxTX6E8hT1TPyvNIT8cF6m9KOWgvSI6RD/dgoS9+4lbMrDAY7Ctdn8/cU5PPq45SrpPLpg8Y6d6Pwzj6j0McIy7/TOfPHtCfj+niIY9lC42uoybm7yVZn8/LzriPBqduj35AJy6OdZ+P9/UCb9Vou6+mfrLvpf8Ez8Pyok+1I8MP3gBJ7+rROU+M3BJP7C9Ur6Q584+WkvWPscX0D1AW2I8ISR6vZArfj/6vCC/VAihPurIpj5HDiI/j8sxPuUXEb+Qxi0/OufdPoXyWj8eZPM9cp9mvscR5z4Cze89dE5jPIMHPj3J730/DQh8P3nk3D044lm8PvoMPiTcuj6So8K9XXsZPRfnbD9cqxi/b/o4PQaksj1O80s/VNkPOc/cdr8skoc+u+sCOsYkeL+cBEs+mEDIvCS6Ej73lGs+IGejPuw0pL1vdWo/MKUhv7Reab2nLU6+qyU/Pwq5DznP3Ha/LJKHPuvqAjrSbho8KgAqvf2eUz9yfCY/L6cRvrXyAb5OPzw/3YKEvTqqBTEkRU4yrXZ/P8rTOT6O0oa9GVIEvBotez+0W7E9pz5lvp32UTxpfng/rnO8Pd7mGz7R87i8sdl7P1am2zsGaFQ+Q1HuvMBQej/g1Am/UKLuvpj6y76a/BM/cBeyPmWQID8n7Wm+ZoooP+BYw7zpM86+2brSuzY8aj+6F9A9eltiPD4ker2QK34/+bwgv1QIoT7tyKY+Rw4iPym9zT3hGyi/wr0BP0+lDD8Jl10/RTLEPVDnOb632+k+yBTJPbUKmD6mc549MVlyP0I2fT9QRLA9kN0tvGSO8z0iyb4+twOAvQoTzjyf72w/DRQlv9EVjr0BlnU9sUBCP7vbDznP3Ha/LJKHPm/rAjpZy3e/gqlNPlvcyrzXUxg+8+ghPvnUoT54Olu9MRZvPyM/G78dCrS9H0t7vhpOQD/ByQ85z9x2vy2Shz6y7AI6qnG5O26kIL3rmVM/k08mP/oaDr7HYf69WrA8P+CChL2QceWxsMa7MK12fz+vKzo+to+Bvchtzbv6NHs/PV2yPQv5Wr6fhl882g55PxVduz3BfRQ+MhC7vCkkfD8wBVK85jlXPowQkDw0OHo/3tQJv1mi7r6d+su+l/wTPyuusD5kiSA/LdyAvnbCJj+r0+s8897LvhHoijydrGo/yRfQPSJbYjxHJHq9kCt+P/q8IL9YCKE+68imPkcOIj80vNI92EcnvwkJBD+JYAs/S3xdP2lJxj114ju+hL/pPnSRzT0zTJE+gqecPRJXcz9CkH0/I8+IPQ3yBry84fU9pl++PqDlPrwcl5g7vZ9tP4zHJL+Jyva9R5c1PfkjQT/f3A85z9x2vyyShz7A7AI6hEZ4v+A0Rj6WgcO8VM4VPhnJKD7NmpE+kZ5LvatwcT9xeR6/jolovdohZr5kGEA/dtEPOc/cdr8skoc+Ou0COvcDzjvZ0N+8G5FTP0QFJj9D4we+16v0vRFuPT/ZgoS9gIMOMg7RsrGtdn8/JA87Pr0Bbr24+Dm7WkB7P0jjtD0Mp0a++i14PCgWej+Qwrg9fecFPsNKvrzLrXw/16pWvLyVUD6Q0fc8mX16P97UCb9Vou6+mvrLvpn8Ez8Rvqw+s7cgP4DikL6ETyQ/MvujPdBjxr4WuB89nOVqP7sX0D2vW2I8NCR6vZArfj/5vCC/UwihPunIpj5IDiI/bGXnPQQjJb92/wg/wpoIP8kEXT+GXM89vXtEvmVB6T7WmdU9cfqDPuS1mD1XKXU/Qlt9P1ayiD2M1Qa80J4BPm1Fvj7x0Zi7yE/zOqmpbT9jESO/McX1vahiOD0BmUI/ItEPOdDcdr8qkoc+HOwCOjOgeL/V5Uc+yyzFvB++CT59OEA+sU+NPkSMYb3453A/ZqsgvwX7T71YiFu+pCc/P4XGDznP3Ha/LJKHPvnpAjoMjEc844VLO9yDUz+0eiU/tGv+vQwK571aiz4/4YKEvQB/urKIxfAxrXZ/P366PD4Sc069BMDGOntIez9Berk9a24qvhpeijw/U3s/zTi0Pd3K4z2IqsC8NVd9P3SMabvgWD8+Q/mVPA1yez/e1Am/V6Luvpr6y76Y/BM/hemwPr32Hj8FOKK+F9IgP02yAD4MI8S+MEZwPU/KaT+1F9A9q1tiPDQker2QK34/+rwgv1gIoT7syKY+Rw4iP/eR/z1KRCK/JEgPP4TfBD+rhFw/DqbYPYJITb4yuug+6+rePTo+Yz6id5I9TGF3P7OLfD9Ys6E9WH8fvFqHEj6dCL0+ytLOvFY7JDyyz20/138ev+1qsL3wyGA9FVNHP5rZDznP3Ha/LJKHPnvrAjpn9Xi/N6FTPj2/0LwQv9U9Cy5wPuXfjj7kYpC9W7NtP+u5Ir/LIYG9DTRSvorTPT8eyQ85z9x2vy2Shz5j6wI6UKiZPPUS5DyBblM/s3skPzlL5L06J9K9L0tAP9mChL00eB4wZ9YCsa12fz9smUA+i20VvaJSADzlP3s/4d3DPbHZ9b2uNps8k+t8PwBYqj0gcKE9Fx6/vFE+fj8e/yg8vyIiPrQvZTtawXw/4dQJv1Oi7r6c+su+mPwTP7Gnlj7TcyA/tibPvinvGD80Ep0+BeDCvicuEj6OUFw/txfQPSVbYjwsJHq9kCt+P/q8IL9WCKE+6simPkcOIj9AXfk9nDkfvz6OFz++5P4+QO9cPwX00D3N/UW+qCrpPqAd6j3D+yU+viWGPU5aej9O4Hs/Ghu9PYqHOrxTUBw+4X66PgjVZb2vE7Q83OltP1fgGb+pHxO9jzOIPeesSz/N1w85z9x2vyyShz6n7AI6f954v3ikWj71qde8qHy+Pbp6hD5SPJU+b2qovTfQaj954iK/TT6UvUtYTL5B3z0/mc4POc/cdr8skoc+K+oCOvfEvTwzARY9qlVTPx8xIz/DZsa9/KC5vctLQj/ZgoS9Zl0QMqwpezGtdn8/aw9HPmxRmryhh2Y8Uwt7P6oF1T2xTYC9fy+kPNINfj/mfJo9WKMgPURWs7z0An8/LxOyPO54/D2g7Zm7x/t9P+DUCb9You6+mfrLvpb8Ez91OEs+CTsgP8cWB7/V9Ak/fz0PP+wirr6mt48+GKYzP7kX0D02W2I8NyR6vZArfj/7vCC/VgihPurIpj5FDiI/pDnYPWA2HL/yhCA/8PbxPhDwXT+SD709gCQzvrM56j4+xPA9Iiq1PX8xaD1IzHw/8ah7P5W/0D2+5028d4obPgkduT6HbKy9y1AGPRePbT8GOBe/pTtgPBwhnT1DmU0/YtUPOc/cdr8skoc+FOsCOkCTeL/h0lo+zdfXvCvj1D18woQ+bOOcPrN+sr32Z2k/oysiv4falL0adEu+34g+P1fRDznP3Ha/LJKHPpDpAjpw9ss8/RMZPTdFUz/XQiI/1GmyvcbYqL36nEM/24KEvczKwDCHSXoxrXZ/P/B5TD4GX9m7XQ2OPJrMej+/YeM9PUa9vLJzojxATH4//V6NPb/RRjyzl6S8lFF/Py8C3Dzew809AL6Yu+mbfj/g1Am/VqLuvpn6y76X/BM/rVMhPhi1Gz/XnRq/XxD7PivHMT8eeY++LnS6PnnADT+5F9A9gVtiPDcker2QK34/+7wgv1UIoT7nyKY+SA4iP0EyzD1VcRm/WuMmPwZH6D6LE14/ViO6PX5fML4lX+o+QvHwPYUoGz1uKUw9bbd9P2evez+U8tc9hwFVvEhcGD6u4Lg+zE3FvfSzGT2YQW0/PD0Wv/8RIz3Hkqc9BvdNP27WDznQ3Ha/KpKHPgLsAjoyYHi/Lc9XPobe1Ly3tu49yfyBPli+oD4dRrO9hCFpP9PDIb/8Yoq9hPZKvuIIPz9StQ85z9x2vy2Shz6H6gI6kjDEPN5pDj26PlM/m+AhPw5cqr2jAqK9CCJEP9mChL1Yh04ylmXrsK12fz932E4+5pDqup3WljyYrXo/VavpPRL67rsu5Z88tkV+PzCkhz0sxK46eB2dvPdjfz8RW+E8PpS9PbWd6bqazX4/4NQJv1Oi7r6a+su+mvwTP1LZOz7w3hY/nEAhv45h8T5TlDs/tDyBviQ3wz4bBgE/uRfQPa5bYjw8JHq9kCt+P/m8IL9SCKE+6simPkgOIj/b4O09epoWv6SZKj9t2+I+LSxdP61qzD1msUG++2rpPqsI8D3YwZA8U0xAPT3pfT9lx3s/tjDYPco+VbwWxhU+GCy5Pl7vxL3ssRk9HzRtP01kFr8MAzg9EcSqPVi+TT8G1g85z9x2vyyShz7o6wI6OlR4v/4MVD6FKdG83vP+PZLGfj4DRaE+Ywiwve5vaT/n0iG/q6x9vb4OSr6GKz8/e8kPOc/cdr8skoc+DusCOm+LsDw4zfE8bDtTP3ytIT9pO6a9CH2evdVlRD/dgoS9oem2MlrqgjCtdn8/UhtQPmLYNzoB5po8XJx6P4gE7T2E/Vo6SSWePFE7fj9Kl4Q94ASKu4PpmLx8an8/xrfjPOdPtT1+aIK5PuV+P9/UCb9You6+mvrLvpj8Ez+tWWM+QlARP2I+Jr+e1Og+/fk/P+HUdL5+ZMg+vxf0PscX0D1AW2I8LSR6vZArfj/6vCC/VwihPuzIpj5HDiI/m44RPueJE793TS0/vs3ePk4dXD+82N89fRpUvhZN6D7cWe89AdTuO7MQOj0F+X0/6eJ7P5n62T10Ale8Sy4SPjvAuT5rEcS9VI8ZPR8abT8vERe/jgFCPSXIrj3PKE0/w9UPOc/cdr8skoc+rOsCOr1DeL+LxE8+AfDMvPBVCD66inc+Ow6iPrOSq73Q1mk/A98hv4eTbb0hlEq+Ii0/P2y9DznP3Ha/LJKHPtDoAjq5Zpw89oXHPDI6Uz+MmiE/dLakvVIwnb22fkQ/24KEvcuBozHKeBWxrXZ/PxqUUD5QRdQ681CcPMuVej+hRe49vBZ7O8tsnTxHNn4/33KDPQ71zLv5TJe8Y2x/P+aF5DxMRrI9ZLyqOaHtfj/h1Am/VaLuvpf6y76X/BM/mneDPkiKDD+fRSm/FV7iPpg6QT/GH3G+xmTLPkiE7j67F9A9RltiPCkker2QK34/+7wgv1UIoT7nyKY+Rg4iP58wKj7XDhG/4ckuP2hM3D7LNFs/4TPvPXWnYr6zV+c+BhDvPQb3Yjvlvjc9J/19P575ez9Y/9s9MwBZvIjuDj7QQro+gTTDvQ5dGT17A20/pMsXv/oMRT3OOrI9MZBMP6HXDznP3Ha/LJKHPtzrAjpkM3i/5BxMPhNVybxTmw8+1cNwPqLQoj4tZ6e9STJqP4DeIb83AGS9iJRLvjQoPz9KuA85z9x2vy2Shz626QI6ZSeTPC1xtDwGOlM/15chP/l+pL3BAJ29Q4JEP9WChL06/4+xTN1tsa12fz91pVA+c3flOp2DnDzYlHo/j3PuPbeRizuJUZ08gjV+P+BIgz2Xg9a7PxGXvKNsfz8Go+Q8RdexPR791TnQ7n4/3tQJv1Oi7r6b+su+mfwTP/Uniz5FgAo/i0Uqv/DI3z6FQUE/rkZxvh9izD7tiu0+wxfQPaFbYjxCJHq9kCt+P/m8IL9UCKE+68imPkgOIj/3/DQ+cQgQv4w6Lz/Jb9s+U9JaPwlm9T1Thmi+y+/mPhkF7z02Jj87wmk3Pav9fT8lA3w/1fHcPU3vWbwJgQ0+E3i6PqrRwr1BQRk9WvpsP0MiGL+zKkU9HbGzPZFKTD/s2A85z9x2vyyShz6h6wI6yCt4v9iMSj5/yse8h6QSPhq4bT4/KaM+AYelvflZaj+/2iG/s89gvSIgTL7aJT8/e8kPOc/cdr8skoc+DusCOmUnkzwtcbQ8BjpTP9eXIT/5fqS9wQCdvUOCRD/VgoS9Ov+PsUzdbbGtdn8/daVQPnN35Tqdg5w82JR6P49z7j23kYs7iVGdPII1fj/gSIM9l4PWuz8Rl7yjbH8/BqPkPEXXsT0e/dU50O5+P97UCb9Tou6+m/rLvpn8Ez/1J4s+RYAKP4tFKr/wyN8+hUFBP65Gcb4fYsw+7YrtPsMX0D2hW2I8QiR6vZArfj/5vCC/VAihPuvIpj5IDiI/9/w0PnEIEL+MOi8/yW/bPlPSWj8JZvU9U4Zovsvv5j4ZBe89NiY/O8JpNz2r/X0/JQN8P9Xx3D1N71m8CYENPhN4uj6q0cK9QUEZPVr6bD9DIhi/sypFPR2xsz2RSkw/7NgPOc/cdr8skoc+oesCOsgreL/YjEo+f8rHvIekEj4auG0+PymjPgGHpb35WWo/v9ohv7PPYL0iIEy+2iU/P3vJDznP3Ha/LJKHPg7rAjplJ5M8LXG0PAY6Uz/XlyE/+X6kvcEAnb1DgkQ/1YKEvTr/j7FM3W2xrXZ/P3WlUD5zd+U6nYOcPNiUej+Pc+49t5GLO4lRnTyCNX4/4EiDPZeD1rs/EZe8o2x/Pwaj5DxF17E9Hv3VOdDufj/e1Am/U6Luvpv6y76Z/BM/9SeLPkWACj+LRSq/8MjfPoVBQT+uRnG+H2LMPu2K7T7DF9A9oVtiPEIker2QK34/+bwgv1QIoT7ryKY+SA4iP/f8ND5xCBC/jDovP8lv2z7O7Fw/N3X3PY28db42ENs+HwXvPYclPzuzaTc9q/19PyUDfD/V8dw9Te9ZvAmBDT4TeLo+qtHCvUFBGT1a+mw/QyIYv7MqRT0dsbM9kUpMP+zYDznP3Ha/LJKHPqHrAjrIK3i/2IxKPn/Kx7yHpBI+GrhtPj8poz4Bh6W9+VlqP7/aIb+zz2C9IiBMvtolPz97yQ85z9x2vyyShz4O6wI6ZSeTPC5xtDwGOlM/15chP/l+pL3BAJ29Q4JEP9WChL06/4+xTN1tsa12fz91pVA+c3flOp2DnDzYlHo/j3PuPbeRizuJUZ08gjV+P+BIgz2Xg9a7PxGXvKNsfz8Go+Q8RdexPR791TnQ7n4/3tQJv1Oi7r6b+su+mfwTP/Uniz5FgAo/i0Uqv/DI3z6FQUE/rkZxvh9izD7tiu0+wxfQPaFbYjxCJHq9kCt+P/m8IL9UCKE+68imPkgOIj/3/DQ+cQgQv4w6Lz/Jb9s+/StcPxSL9j1U/3C+/W7fPhkF7z2OJj87xWk3Pav9fT8lA3w/1fHcPU3vWbwJgQ0+E3i6PqrRwr1BQRk9WvpsP0MiGL+zKkU9HbGzPZFKTD/s2A85z9x2vyyShz6h6wI6cn94v3lhRj6jrcO8fooPPq1Hbz7MCpo+HUecvaPjaz+W6CK/mQUXvTXgQr6gIz8/4sYPOc/cdr8tkoc+GOsCOucX77trMXw88sJZP1ONLT8JnU48h7zWPA0LPD/dgoS9HfzpscDtdbGtdn8/1m1rPsv1oD3SSH28AUx4P6xuFz7mXW0+jZcMvdH5dT9uQgU9h08cvoFnIT1UqXw/26R9vN350Lx7gdo9k2x+P+DUCb9Wou6+l/rLvpj8Ez+XweA+g8DGPksbQL+li5w+d1U4P9wOe75TLoM+vLEYP5Xmzj0TyrK92ChCvd5qfT/7vCC/VQihPujIpj5IDiI/ivEFPza2Ab8Pnt4+AJMHP1rbGrydhpg+CAjNvjvSXT8WPdw9AkoNvLXuC7wZf34/RC17PxUmmD16Exa8XWI2PpsTkj7IN0G9d41oPBMJdT86Agy/GrvfPdaQ7j3CYlI/VNgPOc/cdr8skoc+susCOoLqer+gdUQ+iMjBvPAnNT2kx7Q+ZUUVPnHqY70yKGw/q4TsvozSUryuMzG+6qheP7CvmTlzFFO/X9kQP8rm3zluK+i73s96PHMGWj9B0S0/O6L/PKAkPT03Zzs/4IKEvdydha9qnhIxrXZ/PwU2bD4evK09eMChvJAYeD/Erhg+J/d/PgljJL1xs3Q/Gxz9PIYdKL5icDo9JSJ8P127xruwLXG9jn60PaCNfj/g1Am/U6Luvpz6y76Z/BM/P2nuPhuPwD4N1z2/qyObPsSmOD8S9ZS+X6ZwPgY+FT8wPdA9FsA3vSNXT716FX4/+bwgv1QIoT7ryKY+SA4iP1FzFj9aJP++Zlx8PlF8Fj/uAHW8zU+NPiOVODuLBnY/KaS5PUv5Nbxs0YK8weV+P7VBez/hVko9SpXHu9F4PT5rFZA+tthfPBeig7uMoHU/Tk4Mv1IQkz1oDNM947JTP5vWDznP3Ha/LJKHPuzrAjoyznu/fmwwPkEFrrzoREc925CzPvEx7z3R0DS9YJltP954676eiCg9+5orvmj8Xj+XrJw5FyFRv8SmEz8S1d05TO32u0TCeTxyBlo/4d8tP7ce1DwLryU9bX07P92ChL1g6A2wFLRCMa12fz9Vamw+nkWoPQFCj7xaJ3g/S6oYPlb/dz5UbRi9fT51Pw8I/zxjJSO+QOotPc9efD+eQg08X7DFvZo4Pj16hH4/39QJv1ai7r6Z+su+mfwTP/iU8T5n3r8+duA8v3nKmz5J1jY/UmeRvsJKgT7yeBY/gTvQPb0V4LyUIlm9DDd+P/q8IL9WCKE+68imPkcOIj/mgRo/kxX6vk6nbT5F/hU/Vcd0vOmojz4nQz07c691P//0oT2tNyg8DmcEPe8Mfz+8BHs/rSOVPZUbE7z5dDo+rv6PPqgQZb3mcYY8tTZ1PxIqCr8pDQo+EIT9PR5cUj/W1g85z9x2vyyShz447AI6BIF7v4PGNz6YRbW8KIU8PVZ/tD5ZwgE+f6tFvUoJbT/APeq+W8+mPHGNLb5DZ18/xqqcORchUb/EphM/6dTdOT0fBbxmjHg8cgZaP+XuLT+AQ5s88gYHPQGWOz/ZgoS9AGYpL8DNSa6tdn8/L3BsPvWdpz2fCo28GCl4P1KpGD6BCnc+OP4WvdpOdT/PRP88yowivglqLD3vZXw/QB0/PH9eBr4LeSQ9g499P+DUCb9Wou6+l/rLvpj8Ez8fO/Q+dQPEPsqKOb/CY6I+FXc1PwMkkr4Ku4o+EtoVP4Uv0D1l+V+8LW1hvYJCfj/6vCC/WAihPufIpj5HDiI/3Y8XP9Sk/b6WsHs+uBIWP/CijDzpsI8+QHbTu7SqdT/mmKE9NV97PGAAIT0f+X4/2Mt6P/k8xD2pkEG8og80Puszjz72Hvy9Ti8UPfqTcz+mqAe/B3tFPvBkEj57OFA/XtcPOc/cdr8skoc+B+wCOib8er+rSUM+pqDAvIxBMT0FlLU+d58TPlUkY71QEmw/Lg3ovvE4R7x5kzC+gN1fP5SpnDkXIVG/xKYTP7XV3TnHTwe8/Ex4PG8GWj+m8S0/z2SOPDwWAD3fmjs/2YKEvTCDobId8iMxrXZ/P/v8az7hp6Q9o+6FvNw4eD9bDRg+Q79yPksGEr1znHU/GFsCPSTKH74+QSc9NYR8P5UdJjxYUSi+fLw+PRo5fD/h1Am/VaLuvpn6y76W/BM/Kon1PmPIyz7NhDS/OyatPkFEND84cJa+SRaVPt67Ez/2ItA9BCthuzpVaL06Qn4/+7wgv1cIoT7nyKY+Rg4iP50zDD+a8wS/sOyXPuPGFT/gWQM+I/eMPo4qHb0ktXM/Fv2pPYWxZjzOqyc9NuB+P9LMej/fK8Y9unhDvBxwMz6jNY8+1aH+veGxFT1biHM/K8EHvyalRD4oXxI+ZzVQPwzVDznP3Ha/LJKHPlPsAjp5tHq/h+ZKPggjyLxqsAY99tS8PotvKj5Q4om9xHhpP1fZ5b7CYXQ7rf4xvs9hYD9O+Zs5jJBRv2UIEz99Sd459PUDvHwFeTxi9lk/+9otP0uAgTwV+vI8mLY7P9uChL2cNA0xLB21sK12fz8c/Gg+bV2RPQiYMrxim3g/Kw8UPn2pVj753uS843R3P1DiEz0avw2+x1AGPVU6fT/H5Qg8ry46vvo2QT0hb3s/4NQJv1Wi7r6a+su+mfwTP0QX8j6W69Y+Ix4vvw46uj74vzM/ePiavp17nz7/cBA/ChrQPYJTfDsu+m29BT1+P/q8IL9VCKE+6MimPkgOIj+AJfU+xUcMvz4uvz5vSxM/3rSVPipJhT5SQay9p5RqP4uttj2v0EU8ctYsPV27fj9c0no/gWfFPRq3QrwRKzM+j8CPPizo+L3w3RI9So1zPxcjCL9T9D8+ENMQPtBMUD9y2Q85z9x2vyyShz6M6wI6jJd7vwS5Mz5CRrG8PWRbPZrHrj7tR1A+9CWbvWceaj/7xAO/DFSyPTjVH74qqVY/67iFOZvTXr/aEPw+YVvsOcpwp7uCHYI8FBRZPzqBLD/d2py7xmkIPJAiPT/YgoS9oCWMsTRdUDCtdn8/u9VjPg6JYz0EizG7Ny15Pzt4DT4+Sig+VfqCvCH/eT/avi89ovnfvQ55pTy6LH4/4fwDPLn+Ob7uERw9Tot7P9/UCb9Xou6+m/rLvpf8Ez87suc+d5/kPkyNKr/dmcc+uUk0P1sCnb6pk6k+QEkMP2cV0D2nYQ887ntyvck2fj/7vCC/VwihPujIpj5GDiI/aATLPh3gEb9jR+w+vGcNPwdp8j5L4G4+S6gHvq7GVj9+jcU9f58ePP/NMD3vjX4/twB7PxOqzT3e3Eq8LqIsPjlwlj5BGe29UuQSPZm5cj/ffAu/1MMhPsFGBj54IFA/rtcPOc/cdr8skoc+CewCOqHhe7+W9QU+dSKEvGX89j2WHGY+oeKDPuaqe71fEHA/jbgZv18n7j270vi9dCFIPzNrOzlsRXC/QLOwPrzX/jleHyg6ATOPPE9gVz9Qeik/NfUiveRR8Lw9cz8/2YKEveYxODFj1tEurXZ/PzZ/XT4+JBk9TPa9O2zAeT/2vgU+bnjiPZptRLvhOHw/NwFPPQBYmb0GW807w/J+PyfJLzxFkSa+g9WRPNGIfD/f1Am/VKLuvpr6y76Y/BM/iP7UPozR8z691ie/fk7TPnwtNj/VQpq+71+zPm56Bz9jFNA9Jek/PO3ndb2CMX4/+rwgv1QIoT7qyKY+Rw4iP/hyoD65LRS/9SAMP3NQBD86MCM/v/FJPpVpMr5VYjk/oafUPYT27DtZwTM9ilx+P6tbez85sNo9k7VXvC7THz4wB6I+8F3dva25FD0PFXE/BsMQv1GS3j1U4ek9OT9PPyPZDznP3Ha/LJKHPoHrAjrBVnq/XRbwPRbRbLz6ujA+flgCPgCwmj63/ia9Q6BxPwb0Hr/WAXE9/+gPvr3YRD9AwQ85z9x2vyyShz5R7QI6mP/1O+7ioDwcdFU/VKUlP7gCkb2NloS9XqJBP9+ChL24qB+w2mCKMK12fz++R1c+DlakPNGMUTxcNHo/mRn9PcKMcT2WMgg8YpR9P3gFaz37+Cq9HJDJu5NZfz86MKA8+2+svTzXBzuRCn8/4NQJv1ei7r6Z+su+mPwTP7NbuT6EjwE/77Qnv7Ro2z7aujk/2XCQvm38vD7D+wE/gxXQPeIjWDzyRHi9/C1+P/u8IL9WCKE+6simPkUOIj/VzHg+BV8Tv6FYHj/l7fM+jUpCP8QRJD6f2VC+WuYYPxjh4T2WPKY7Sco1PVoufj+kvXs/xA3jPfP1X7zHrxI+UbCtPk3Fzr3QCxY9rD5vPwJCFb9pjoE9Y7fJPcvQTT+a1w85z9x2vyyShz6h6wI6np55v1NGKD6F+6W8dzoXPtK2RD6nk54+zjyDvbrTbT+3RyG/nvVfvJkaNr5rfkE/L8gPOc/cdr8skoc+yeoCOsndbTya7q48auRTP/y5Ij/pt6S9Y8CcvVCSQz/igoS9ZOrwMPrbJDGtdn8/OpFSPkcH5ztIco48qnt6Pwie8j0ZtKQ8LGeEPIwcfj+/0349FzeJvC9Ddbx7cH8/YuLcPAqx5DzoGjq6m85/P97UCb9Wou6+mfrLvpn8Ez9HqZo+iNoHPyxJKb+PFt8+1JY+P11Zgb59Kcc+2t31PgQX0D2AEWE80Kp5vRwsfj/5vCC/VQihPuzIpj5IDiI/paZHPgI7Eb8vlyo/BbviPq2WVD+gsQY+/3tivv///D5RTus9oTBnO4YANz20C34/APN7PzGH4D0zeF28Xd4NPpu0tj5C0sW9aAUYPY2sbT9Qfxe/PdJFPeK4uD37sEw/ANkPOc/cdr8skoc+IuwCOoGheL/dPUI+h5i/vE2WET4DJGQ+hs+hPi3xnL1jRWs/MbYhv2arQr1Sm0e+BbI/Px3MDznP3Ha/LJKHPhzqAjplJ5M8LXG0PAY6Uz/XlyE/+X6kvcEAnb1DgkQ/1YKEvTr/j7FM3W2xrXZ/P3WlUD5zd+U6nYOcPNiUej+Pc+49t5GLO4lRnTyCNX4/4EiDPZeD1rs/EZe8o2x/Pwaj5DxF17E9Hv3VOdDufj/e1Am/U6Luvpv6y76Z/BM/9SeLPkWACj+LRSq/8MjfPoVBQT+uRnG+H2LMPu2K7T7DF9A9oVtiPEIker2QK34/+bwgv1QIoT7ryKY+SA4iP/f8ND5xCBC/jDovP8lv2z5T0lo/CWb1PVOGaL7L7+Y+GQXvPTYmPzvCaTc9q/19PyUDfD/V8dw9Te9ZvAmBDT4TeLo+qtHCvUFBGT1a+mw/QyIYv7MqRT0dsbM9kUpMP+zYDznP3Ha/LJKHPqHrAjrIK3i/2IxKPn/Kx7yHpBI+GrhtPj8poz4Bh6W9+VlqP7/aIb+zz2C9IiBMvtolPz97yQ85z9x2vyyShz4O6wI6bQxlPav34D33Zzo//5gsP9VFGb4y6ha+80E1P9eChL0I7bQvy8QRsa12fz+9IHg+3JglvUGwCDxWJXg/WW0BPuyz772nL2W8zSV8P49Ocb3C6KA9pftVPJy9fj/VFac8WNsvPouG/7wgBHw/CHkZvxg2v74v1cm+NYYWP8bKF72Q4zE/1tPfvqjdET9bu8o+FaNKvnDWxD0IO2Q/gWKiPdF1nb2TejY8+mp+P6i3Ir+Q+J4+QcCoPoIRID/5t0O++QQtv1hgBD8Advo+X4y3Pqs2DT4csVu9lvZrP/2v27wWZP49dimHvLTjfT/13Go/QWAePvI3nLyhcbs+imsSP3ugkr0KmU09/ctQPxpoJL87TSy9wVeDPfA+Qz+z1w85z9x2vyyShz5F7AI6G+ptP+Pfqb57jyc9C28gPuULCz868HY+0HgqvnRuST9o2jC/FP89vrncRr6r2Cs/z8YPOc/cdr8tkoc+musCOtH5VT3sQOA9Xuc7P/+YLD/VRRm+MuoWvvNBNT/XgoS9CO20L8vEEbGtdn8/H+59Pk4BJr1E2Bs8X8Z3P1/bBz68nfC9IhZRvEbtez/eLoW9H2ehPYI/RjwupH4/VXEYPV0WKj6z+yi99Qp8Pwh5Gb8ZNr++L9XJvjWGFj9WsBm91P8xP6Hx3r7CDxI/esfKPoPBSb4yDsQ9hUdkP17EmT00/469XyxrPNWffj+otyK/jfiePkHAqD6BESA/87dDvvgELb9ZYAQ/Anb6PgfGvD50mAw+IPJhvSzuaj+fgla8Leb9PVc6lbzN9X0/CqZrP4bEHj7nmpy8UF+3PkvBDz98IJS9XCNKPSKjUj/8gSO/1PEuvTrqhj3C80M/29cPOc/cdr8skoc+IewCOru2bj9m0qa+lowkPQ5UGj4awwg/kJ16Pn4IKb5kyEo/kIAwvysyPb78WkW+v14sP4DFDznP3Ha/LZKHPjLrAjo/7C89vlzfPQnmPj//mCw/1UUZvjLqFr7zQTU/14KEvQjttC/LxBGxrXZ/P2t0fj54Cia9V5UdPKq9dz9jcAg+lbLwvedCT7wF6Hs/Q1GGvVpyoT350UQ8wqF+P36adj2e+SM+WndMve7mez8IeRm/Gza/vjPVyb41hhY/cWkevXNGMj8vtNy+GI4SP5Plyj4Gjke+lRnCPXhmZD8/IIg9+npkvRjsqzxS+n4/p7civ474nj5DwKg+gREgP/i3Q775BC2/V2AEPwN2+j5Qda4+2T0OPrfPUL1Rrm0/hB6uO9Qp/T0kC6i8iPp9P3g2bT+rjCA+z1yevOu0rj4zCAo/MMqWvXcVQj1kblY/c4UhvxxPNb3uiZA9ynZFP6rXDznP3Ha/LJKHPk3sAjrKXXA/5RigvpjqHT2rsQ0+ICgEP3cFgT5TCya+T2RNPwj+L7/ftzu+V4VBvgxDLT97yQ85z9x2vyyShz4O6wI6ujT6PCPB3j1INEE//5gsP9VFGb4y6ha+80E1P9eChL0I7bQvy8QRsa12fz+Pqnk+zbQlvaLBDTxkDHg/UiEDPnny772o3l+8Fxd8P0Xyd72cCqE9HNJRPB63fj9eCYw9KWQjPrEiTL1Gyns/CHkZvxg2v74w1cm+NYYWPyyTJL0TozI/X7HZvlw2Ez+TDMs+l6pEvraIvz2KjmQ/Wl50PbyEOL0XNdc87jF/P6i3Ir+P+J4+QcCoPoERID/1t0O++QQtv1hgBD8Ddvo+QAOaPv1WED72Vji93i9xP1HoTTxu2fw9fHGvvD/2fT/Udm4/aq4kPiFworz3u6Y+LPkEP7eal73UODk9MaBZPwDAH7+U1Dy9iueePXqzRj901w85z9x2vyyShz5I7AI6sNpxP/91mb7cXhc9tpACPm++AD8g64M+F/MjvlQyTz9qRjC/VNY6vmmAPL45YS0/Q8UPOc/cdr8tkoc+H+sCOqR1jzy+CN89qLpAP/+YLD/VRRm+MuoWvvNBNT/XgoS9CO20L8vEEbGtdn8/WsdzPodIJb21zfQ78Wp4P6g8+T2JAO+9syh0vFVOfD+dj169Q4egPeq2YTwBz34/mPhkPR18KD6naSq9TeF7Pwh5Gb8aNr++MNXJvjWGFj+53yq9OwIzP8yB1r595hM/HzTLPhayQb4E5bw9HbdkP/Upej0KjkG9ADDOPHwnfz+otyK/jviePkPAqD6BESA/97dDvvkELb9YYAQ/BXb6PqwTkT6bKhE+D6UtvXSRcj8ZLg07t0v9PTrRpLxP+30/pWNuP7trLD56Eqq8fiulPtHhBD/PvZK9VgszPfPAWT/wuh+/RNFBvbmasT1cc0Y//dcPOc/cdr8skoc+TewCOsVUcj9yyZa+lrsUPZAPAT5pVgI//lyDPm0YJr7aLU4/ZHsyv6jFO74V7za+pGsrP0PFDznP3Ha/LZKHPh/rAjoSItA7f23gPTi9PT//mCw/1UUZvjLqFr7zQTU/14KEvQjttC/LxBGxrXZ/P+omcT5JFyW9fJvjO1WUeD/lb/M9bZLuvX0qfbwNZnw/6UBTvVRLoD3oxWg80th+PyMdDz0SWi4+eYMDvSP4ez8IeRm/Gza/vi/Vyb41hhY/KCEwvfhRMz9+wtO+znwUP9lUyz7vMz++E666PavYZD/XBI89mLF6vaahljy22X4/qbciv4z4nj5AwKg+gREgP/W3Q774BC2/WWAEPwJ2+j7nFpw+0CMQPmLTOr1e2nA/bTZ5vGr6/T0ZD5O80vN9P0YXbT9/JzY+U6yzvMLsqT45cQk/qPSIvb8ILz2vBFc/A08hv4+eQr05n8U9bN5EP9fXDznP3Ha/LJKHPiTsAjog3HE/jSSYvgASFj3ohgg+PSsIPzqJfz6JtSu+WqhKP2YKNr9eFD6+jqsxvufTJz+CyA85z9x2vyyShz4S6wI6ClbpuTzA4T125jo//5gsP9VFGb4y6ha+80E1P9eChL0I7bQvy8QRsa12fz8p3nQ+1Fwlvdjx+zukWXg/iKT7PcUt7734anC8VUR8PzFAY73mn6A9XMhePMjKfj97UaE8NOYwPles67w7/ns/CHkZvxs2v74w1cm+NYYWP6FEM728gTM/BxTSvhfYFD9OaMs+R7U9vhtauT2Q7GQ/go6fPbCumL1zvUc8+Xx+P6i3Ir+N+J4+QsCoPoERID/xt0O++gQtv1hgBD8Ddvo+tkSvPgcnDj4CyFG9KIhtP1QP3byOZf49Yv2GvGjjfT+Nz2s/xzY9PviiurwfBK8+r80NP8aygL066Ss9GUJUPwvJIr+xckG9NrLTPYlsQz8p2A85z9x2vyyShz5J7AI6W0BxP+E1mr4mHBg97R4QPoY8DT9a2Hg+9jswvgBxRz8qxzi/jPQ/vh1LLr4H5iQ/KMkPOc/cdr8skoc+D+sCOhxW6bkP++E9xtQ6P/+YLD/VRRm+MuoWvvNBNT/XgoS9CO20L8vEEbGtdn8/JGJ7PsjTJb0hbBM8WvB3P14IBT7rN/C96uxZvG4GfD8nXH+9JjChPaYqTTyor34/X/rcPIRfLT5TqRK9AAt8Pwd5Gb8XNr++MdXJvjaGFj/ERDO9u4EzPwgU0r4Y2BQ/TmjLPka1Pb4ZWrk9kOxkP/bznz2qWZm9+FFFPH16fj+ntyK/jviePkPAqD6DESA/+LdDvvgELb9YYAQ/BHb6PkGbvD6RnQw+7L5hvcP2aj+LbbC8HzX+PceTjLwk7H0/3MVrP6ZPPT54u7q8fTGvPh7pDT/2jIC9juYrPSAwVD+mziK/QFpBvefR0z1rZ0M/s9cPOc/cdr8skoc+RewCOtM5cT87TJq+JDIYPaZsED7xWw0/0q54Pv1XML5uXEc/wdE4v4kCQL7lOC6+WdokPwTHDznP3Ha/LZKHPo/rAjoMItA78ffhPcVZPT//mCw/1UUZvjLqFr7zQTU/14KEvQjttC/LxBGxrXZ/P/sUfz6XFSa9bKkfPDyzdz+jIgk+a8vwvXYUTby24Xs/jqyHvbd/oT3XHEM81J5+P6QHST2ksSY+sbY9vWn+ez8IeRm/GDa/vjDVyb42hhY/JCEwvflRMz98wtO+znwUP9tUyz7yMz++D666ParYZD+dT5E9RROBvUqRjzwazn4/qLciv4r4nj5BwKg+ghEgP++3Q776BC2/WWAEPwN2+j6VdLc+cTkNPmyUW702+2s/L/Bju5GG/T1CEJ+8EPt9PyLgbD8dvDY+2z60vBD3qj5PDwo/hCKIvWQVLz1eoVY/H2whv+0bQr0+TsY9UMREP7TXDznP3Ha/LJKHPkTsAjqFtnE/UKaYvvWRFj0rYQo+YecIPxmbfj79ZSy+1jJKP4ZINr9BbD6+yzAxvlGSJz9DxQ85z9x2vy2Shz4f6wI6oXWPPFDs4T0yRkA//5gsP9VFGb4y6ha+80E1P9eChL0I7bQvy8QRsa12fz/vd3w+OeclvU4CFzyF3nc/XzwGPnNj8L2aKVa8x/t7P0cGgr2sR6E9sDhKPNSqfj9yDYo9arciPirjUb3r0Hs/CXkZvxk2v74x1cm+NIYWP8jfKr06AjM/z4HWvn3mEz8dNMs+FLJBvg7lvD0dt2Q/pLB/Pak3Sr0bmcU8/Bx/P6i3Ir+O+J4+QsCoPoERID/7t0O++QQtv1dgBD8Edvo+4umjPi1cDz6mMES90IxvP5j1ODzk5/w91yOuvEH3fT+BHm4/MjYtPivaqrxAg6Y+C5UFP4nRkb02MzM9iVVZPxnIH788R0G9kWyyPVpmRj/c1w85z9x2vyyShz5O7AI6ryVyPxJil74fUhU9/LgDPulMAz/yzoI+gRQnvhibTT/jxjK/yEo8vrgLNr7qIis/3McPOc/cdr8skoc+FesCOrQ0+jyA0uE9fmlBP/+YLD/VRRm+MuoWvvNBNT/XgoS9CO20L8vEEbGtdn8/qJZ2Pp98Jb3inwM8IT54P61y/z3QdO+9rH5qvFQ0fD8Iq2q9e8agPUMkWjzuw34/6hKDPR6KJT5ryT29WNJ7Pwh5Gb8ZNr++MtXJvjWGFj85kyS9E6MyP2Gx2b5bNhM/lgzLPpKqRL6viL89iY5kP0HTcT26kTS9jCvbPFY2fz+ntyK/jPiePkPAqD6DESA/9bdDvvoELb9XYAQ/BXb6PmEBkz4X/hA+4/MvvRlHcj98rhM8PwH9PXvRq7zH+H0/tIBuP3m0JD4bdqK86YGmPiNoBD+rGpi9IMA4PY73WT+SUh+/EBo9vXPOnj1PC0c/ptcPOc/cdr8skoc+UewCOurncT87C5m+gvUWPWoFAz41hAA/4DKEPkTuI75HS08/5hwwvz34Or7/lzu+2JgtPzXHDznP3Ha/LZKHPhfrAjo+7C896qThPZRjPz//mCw/1UUZvjLqFr7zQTU/14KEvQjttC/LxBGxrXZ/P3LIcT4hIyW9ArznO3CKeD9k1PQ9A63uvScBe7xoYHw/6/dVvdZZoD3/E2c8g9Z+P00aOz2Fmis+DrAVvVzvez8HeRm/GTa/vi/Vyb42hhY/f2kevXZGMj8stNy+Fo4SP5Xlyj4Fjke+kRnCPXdmZD+lL4U9ZRtbvaIGtTwuB38/p7civ474nj5CwKg+gxEgP/S3Q776BC2/V2AEPwR2+j7Xq5Q+JtcQPlbyMb0CBnI/diLTu7ak/T0NCJy8F/p9PzpmbT8tMiA+kwOevOTFrT6vBAk/QM+XvUliQT1XElc/MPwgv2TTNb0ZEpA9pedFPzPYDznP3Ha/LJKHPkrsAjqpiHA/2EefvmMcHT2x4Qw+DGUDPz2ogT5ikSW+481NP5umL7+vmTu+6NJAvh6qLT/Pxg85z9x2vy2Shz6a6wI6zflVPdJd4T2IIDw//5gsP9VFGb4y6ha+80E1P9eChL0I7bQvy8QRsa12fz+AT3I+GS0lvbQv6zsjgng/e/71PTTD7r1hMnm8qFt8PzI9WL3lZaA9gKllPI7Ufj/QOdA8ckIwPrqy77zb+3s/CHkZvxg2v74u1cm+NoYWP36wGb3V/zE/nvHevsQPEj99x8o+hMFJviMOxD2FR2Q/VXiYPVvYjL35IHM8SKd+P6e3Ir+N+J4+Q8CoPoERID/0t0O++gQtv1ZgBD8Cdvo++oqlPjsxDz7mI0a9EUVvPw76uLyLPv497oGLvJ/qfT9Eu2s/haAePmh3nLz5+bY+2lAPP7WRlL241kk9vu5SP1hEI7+tJy+9ubmGPXUnRD/H1w85z9x2vyyShz5G7AI6l8puPyB1pr6ZMCQ9YgEaPnBvCD93MXs+SN0ovor3Sj+3WjC/GyY9viL/RL7bjCw/6cUPOc/cdr8tkoc+HOsCOmwMZT2r9+A99mc6P/+YLD/VRRm+MuoWvvNBNT/XgoS9CO20L8vEEbGtdn8/vSB4PtuYJb07sAg8ViV4P1ptAT7us++9my9lvM0lfD+DTnG9wuigPZ77VTycvX4/1RWnPFjbLz6Lhv+8IAR8Pwh5Gb8YNr++L9XJvjWGFj/Gyhe9kOMxP9bT376o3RE/W7vKPhWjSr5w1sQ9CDtkP4Fioj3RdZ29k3o2PPpqfj+otyK/kfiePkHAqD6CESA/+bdDvvkELb9YYAQ/AHb6Pl+Mtz6rNg0+HLFbvZb2az/9r9u8FmT+PXYph7y0430/9NxqP0RgHj4DOJy8qXG7Po9rEj92oJK9C5lNPfrLUD8caCS/NE0svb9Xgz3vPkM/s9cPOc/cdr8skoc+RewCOhvqbT/l36m+fI8nPRBvID7nCws/M/B2Ps94Kr5zbkk/adowvxf/Pb673Ea+qNgrP0PFDznP3Ha/LZKHPh/rAjqrfBw9oyPgPZgvPj//mCw/1UUZvjLqFr7zQTU/14KEvQjttC/LxBGxrXZ/P0Mlfz60Fia9j98fPCyydz+4NAk+9M3wveTbTLwS4Xs/y8+HvRKBoT1q8EI8iJ5+P8n8EjzDnDA+EgkBvTIGfD8IeRm/Fza/vjDVyb42hhY/xsoXvZDjMT/Y09++qN0RP167yj4No0q+b9bEPQc7ZD93YqI92HWdvR17Njz6an4/qLciv4n4nj5BwKg+ghEgP+i3Q776BC2/W2AEPwB2+j5vgb0+2YEMPnDSYr1xyGo/ye5TPD3V/D1n0a+88PV9P7LpbD8cECQ++NOhvBOBrz43/Qo/uM+TvXkWQD0E2lU/StYhvwBjNr3WNpg9dRxFP6bXDznP3Ha/LJKHPlHsAjrvVHA/xfKfvvPEHT1lTg8+CcIFP30cgD7rqye+q2lMPzwsMb/0eDy+D08/vlkoLD97yQ85z9x2vyyShz4O6wI6tRlAPPpm4T3b9UE/LBopP0qpHL4x/zS+AKU2P92ChL3aWEGxDCIcsq12fz+ArHg+z9NIvXXzBzyZAng/Nu8BPmnTEb6uezu8dUh7P1Hhcr2KI8Q94GFEPCxafj9nR449G8Y3PtDadb2Vvno/irwYv6Zsv77NUMi+HbUXP+B8HTxx5jI/jB3JvjMDGT/o/KI+kpw8vvPli7xtBG4/emKiPd11nb3JejY8+mp+P2VpIr/5XqE+3lSrPhMXHz8j1T29uEkzv2LH1D6DGBQ/rgePPh+/ij5fOEy9R3hrPy74UT2t2hE+ePBcvTmsfD8I3W8/Idg/PiE7vbzHjJY+tYICPx3shr2WhSA9oltbP2ZDH788MYm9RFm1PdlmRj/U2A85z9x2vyyShz4e7AI6c1h0PwTzjL56Bws9OrrgPdcU/j53XIY+G0MkvsnWTz/jzC+/XixUvlryN76iVyw/KsYPOc/cdr8tkoc+7+oCOm8807w8mOc9ae5GPx1jJz8SfCu+6ihUvnNKNT/jgoS9zGwssvr5ibGtdn8/AxdCPsc1mb0e6C87vKB6P80ojT32Il6+Mx4UvPtEeT9gJA67H7UVPpQUJTxQPH0/IkkTPnjzVz6tHeW9Mdt1P5BdGL+uJry+rk3Cvt0FGz/I87I9uRUzPwnSl74P7iQ/5794Pg5UQr6jMbC7jYdzP3lioj3idZ29kno2PPpqfj/U1CG/7qqlPoEBsD6nSh0/f/YtPlzjLr9fd4s+p+onPztxdz574vs+DRjlvYgyVD+/ZME9/sk9vvhfIj3WMXo/521yPy8kXD53JNm8rfNyPiGc6D7sQIK9AD8FPRxSYz/ipRq/B+bTvXe71z0+ekg/YtwPOc/cdr8skoc+YOsCOqnWdz/fum6+ZXrrPGYnsj2JIe0+b0eOPvRaH75Ju1M/8lkuv2sLc77+4y6+ytorPz3MDznP3Ha/LJKHPk7qAjqGBVO9bvzsPQROSD+CkSs/98gWvqxDVr58WjI/14KEvaYp67I+AR2xrXZ/PxsXIT7tbbi9YBe8uzzBez8zoQ89mvWBvopXc7yGbHc/ukMDPVATLz4UrG083xF8PyvDPLttU3A+2vOzvXjUdz9btBu/RcGtviKhtL4g9h8/Y4WzPdNkND8vvFK+U2EsP3ZvdT5bm1O+61Z1PaNbcj9/YqI94XWdvbt6Njz6an4/JYghv0LEpz7AULI+9GMcP8zm+D14bjK/F2gEPl/cMT/CziU+5cI2P91QUb7CXSY/L0gDvfkBNb6rikg95oV7P61tcj+G/G4+GbvrvHwpYD72QeQ+5JFmvYWF4zx7lmQ/nX8fv6D91L1OLvA9uS1EP6jZDznP3Ha/LJKHPlXsAjor/3g/HZs7vuoMuTyFaRA+byjzPpWvjj4YjyS+FrJRPzE1Kb+qSYO+e5kBvo2cMT8UxA85z9x2vy2Shz6m6gI66q9xvZvwqj3TySA/N8dDPylfWT7X3uA9sS0ZP9yChL2ioKAyRIjwMa12fz9LXjE+9IQsvEAyxj1Y5Xo/+i2sPRQraz73XFS8PzR4PyyY97vvlzm+N5WCuy3Aez+BVMy9ZYRpvUrBNb3lDH4/jEEevzv7pr42OrC+23wgP/xTkT0uQjU/DTw5vhzNLT98hxQ/g35rvZIbSz1QmU8/aGKiPeF1nb24ejY8+mp+PyeIIb9FxKc+vFCyPvJjHD9FZOI+WAEWv2SVPT6uQSc/mdOBPfg3ST96Yr69iJ4bP0tHq74Dpjw+XLQMvbdubD94yXA/qXiXPoBoFb1flyY+xvwJP0WAtz3R3mW9OOxVP2tPQr/lyJ09j/F5PmhAGT8c7Hk5OEhjv+yd6z5KEfE5nxlBP6Uhhb5bUQM9QBwaP1KqJj/AKzE+QlAhvj7aOD/LfBe/coemvSm8p73YPUw/YdEPOc/cdr8skoc+uusCOq47hL3WWZc9d4QIP/szOT+oGKc+P4lhPlMtET/ggoS9YFGEsMDGdLKtdn8/8iJ9PhmoAD1OZsA9TMF2P7OtQz6KTQI/q5LJvSlgVT++2dO9G2DIvthQhT15fmk/Xq8TvRokWb4WcR086P55PxihGr9UsbC+taO2vgahHz9yqie9JTM5P8AeQr6Rnyk/HlirPios3T2RQPy8HYVvP3l5nj25IqG96jZ0PGdofj8niCG/RcSnPr5Qsj7yYxw/+ZDwPtZqDr/g2rU+5w4WP6A0ez04Dkc/M0CAPTtnHz8HvxG/mVV7PV7cjD1zIlE/55ZoPzQOwD5ncD29uEc2PqWQ/D4wWlI+zPv3vawnVj/gojm/ZOj4PWGuoT4ViBk/QsKROXz+V7/taQk/NhrlOTJVMD+OENa+FyZTPeUJFz+jwEE/zi0nPi+DU77cJBk/o/ghvyFCkbwPapu9Pj1FPyYnzDaHxXW/wkePPpXy8TmhmHq91d+UPTrkCD8toTk/qcymPj8IYD7j3BA/1oKEvQrWArNVjMoxrXZ/P373bz6yfhU9TcjEPQB6dz/HPjg+fmEGP6Azwb2bmFM/AK66ve8+zr5YIn89qploP/JLizxTF3S+KDR4vGKNeD8WoRq/VLGwvrWjtr4IoR8/IoiFvM6MOD9xnjC+E8krPymIrT48PMg95v3hvItwbz/FOw49uP3FvUjfJj2ebn4/JYghv0HEpz7AULI+82McP/WQ8D7Vag6/4dq1PugOFj+XjIY9L+U6P+OcbT1fgC0/+/kQv7MKrz2EeWw9dFVRP6Hhaz+FbLc+2Ow0vQFaEz5+1e0+NstvPjf1A76NIVg/ZHtCvznGdz0bUpY+oLoTPwxG2DhcCF2/OScBP1Y36jlKLTE/6+bNvuIYSz1V6xg/V1pCPxf3GD5N6z++G+oaP6gwI7+yaU874tm/vU/HQz8GsEU5NhF2v208jT4tsAU6GZtDvYMzkT3CvAo/zzQ6P2oepD4s/Fk+qHYRP9OChL1eGbqy0+ovMq12fz8Wa1w+LT7sPH+74z1kQ3g/q2klPiR5Aj+gIJi9eoBXPwFgkr0n9si+8M03PYR2aj/TuBs8/MdRvol2d7xYh3o/GKEav1WxsL63o7a+BqEfP178mTzaYzc/AiZBvirmKz8Yib4+5NKlPaLYybyVn2w/3xMPPQdgor0fkze6jwl/PyaIIb9DxKc+vFCyPvNjHD/1kPA+1moOv+LatT7oDhY/mJmRPV3rKD+871E99As/P1XFDr+Un/E9a14tPfANUj+UVW4/QIGqPqAuKL0TNBM+U3r9PglHdD5x8hK+BbNSP4pkQb+i91I9APB+PhSYGj83BTe7JoBWv1a7Cz9bVBQ6M940P3481b7lVFI9qOIRP+doPj/VlSg+slhLvuTbHT+t5SS/A3/Vu/12Fb6TNkA/sJsnOszcdr8hkoc+LxInOjJam7zUAJg93bcWP5NmOz/2ZJI+h3U+Plz4Fj/ggoS9rdFyM9DUOLKtdn8/HF5VPjLacjzgIfk9aGh4P8zTGj5kde0+y/dmvSkCXz8bYH+9LQG4vsvu6jztP24/lH1nvNPcIL6BKXi8EcR8P19wHb+fz7K+7SfAvqRgGT92R4c9H6U0P9Rair471CY/iR7KPjRuYT1Ug4C8acBqP3Rioj3ddZ29zXo2PPpqfj8zkSG/1oWnPs8Lsj70fhw/DbThPokOFb9g/Is+zUIgPwNTAD6X0Tk/kw4wvM4eLT95Ive+oFqsPbX5TTx/JF8/rPFzP+VDlD7sPhK9AlqpPdia+z58sVs+cWsBvmimVT9eg0K/6ajRPMhwSj4Oax4/3xIsu3qdXr/7zvw+9xbbOXYXRD/xHbm+Wpg2PQiZBz/L6Dc/I74mPl0eOL5q5yY/5MQrv4W37byZcCC+amI5PwCzPTrL3Ha/IZKHPiMjLTp2/Hg8HLG9PQj+Nj9DFDw/gT0dPscZqz3Zzic/24KEvRs9xDIQZz0yrXZ/P6ozVD7rS4Y8I43wPYqYeD8+WBA+zj7MPvspE72txmc/cPthvSmSnb5iODE8SSZzP/QDcrx0Jle++TgUu6RBej8LcyS/eGu2vsUf3r51jwU/AhPTPXriLj+JmMm+wzkbP10Tzj5jDq87lde5OwpXaj90YqI94HWdvY96Njz6an4/Ucghv+YDpj4UY7A+uSQdP2zogD5wyii/XiyqPaQbND/cWpE+ThMuPxlLLb4xjic/NtUHvjyy/714/Gm8qrB7P/V4fT9f+Ag+xhqHvB7YHT3WFBc/bEwBPgbtvr2suEo/hEU/vwm3Db11auo9z18nP/mPNTcY7HW/GD6OPpUx9DkFE2I/neMovpeWpjyxpeA+NDcYP/hTzT1Y4Zu9+UpLP2K1Kb9X93O9ZXsHvrMHPD/USiI6zNx2vyWShz5ImyU6U/r0POYE3j2+Qkw/LYo2PzKKlzu6mxm9pjkzP9uChL3/7d2yUFTFsK12fz9IYFQ+LzRsPBBg0T32CHk/Cov9PX5LkD6lSki8wYxzPwwwNr0B4V2++cMBvIOmeT86iM276eoYvvjE1Lx5CX0/BDQjv9n6t77ujty+WDEHP5hACT72cSc/LzX7vkxVDz/pt84+M1alvWqwMz3WBWk/cGKiPeN1nb2lejY8+mp+Pw0bIr8+raM+utStPvYhHj+1h/E9eAkuvyQkyj6qThs/k/q3PuIdyD6uk829PGlXP/ccIz0mTFW+kW6zPEAdej98+3Y/Ee0MPV8Bi7tUhYU+quI+PwHCIz3NPTe9BOQpP5+3G7+EXZu9g3egPX9EST/8zw85z9x2vy+Shz6A7AI6RvlyP3/ua73yt+g7DHuePqgE6j47m/c8fV9/vDiHYz/pySC/4Ez3vTaS+72aQ0I/mADwOc7cdr8mkoc+qf8ZOhlPCz3g0+Q9d1RIP4uAMD9Dzbi9EurfvS3XNT/WgoS96FlNMfa2EDKtdn8/Y1hfPp4ZZbzBF2g9sGN5P3+u5T3TkJ09uZY1vAKbfT9nMS29/HSEvePlt7kMPH8/BZLcO6/9WTw3Ega9mNV/P1AEH79Jd7u+IibUvjkrDj+c5v09HeMmP4CIAb/uDw0/nLHLPqEgNr6wh7I9XVRlP3Nioj3cdZ29xXo2PPpqfj/obSK/PDyhPl4vqz5cJR8/qTC2veb+Lr8N8vw+HqQHP4fEwz4Er1Y+ciSIvbu/ZT9Yn848bCFVvV8RT7pSkn8/em5sP6gk1j3dOVO8ncW8Pk8WID/2rBG8Ik3VOw7ARz/yfBe/4cVzvZtziT3fFU0/UMMPOdDcdr8nkoc+xeoCOlWPdD99+PS9JqJxPDAyij6hPwA/4YHCPRs4ZL0hwls/FSMrv5mrJL3Nr569xxI9P7p0mDnP3Ha/KJKHPqz5DTqFDBk97zDhPccFQj+/cy0/XAsNviE2D77zczU/24KEveeRMrLSiIuxrXZ/P2yZdj66Hx69V9q4PLozeD85cwE++lW0vfM9Brxe73w/dMRxvUiQZT0oa7s7eSV/P3jyHTzSChQ+UpIXvQ0ffT+6xBq/y2m+vnUrzL6jphQ/PDMvPPhKLz9Okuq+oRERPy6yyj53wkq+M+rEPQ87ZD95YqI933WdveR6Njz6an4/iqgiv0hxnz6hQak+rOAfP0JiFr5F6y+/10j4Pt1HBT83LcU+UJIYPgoZbr0armg/9kGEPOk7jz3KOIG8yk5/PzNXbj/G8Rc+4t+VvOl3qj7JPQQ/NViAvW1/Gz0iZVo/Fvwev5AHQL1LSZE93HZHP3XcDznP3Ha/LJKHPrbrAjqkFXI/2c+CvrMHAT1qfks+UIsGP11FXT4oeA++LZNPPzumML884PC9RqoCvqjhMz/cSzE5z9x2vyuShz50OAU6GYccPRbr3z1EVD8/GaYsP5f1GL5PmBa+9j01P9aChL3CoaKyYOx7MK12fz8WsX4+WRo8vchpgjyMpHc/+rkIPgq3CL4GK5O7cGR7P+tJh71/lLY9VfyiO4Jqfj/kYCI8unw4Psk2KL0ilHs/B3kZvxs2v74x1cm+N4YWP/iDzrz4TDE/O3nivge6ET86t8o+F6ZKvuHUxD3NO2Q/cWKiPdt1nb2vejY8+mp+P6e3Ir+N+J4+Q8CoPoERID/g8ie+R+suv+yK/j4fTQI/prrCPvb2ED5ktmu94oFpP+ezYjwuStw9p3aivIFwfj/sbm0/8a8iPoV4oLyF/6w+efEIPxAulr24Ij89KCVXPzcXIb9q2TW9Z8KWPbC9RT+f1w85z9x2vyyShz5N6wI64MVwP+oxnr5YChw9EU4LPs63Az9FkYE+TwkmvoiWTT+fcjC/xEI7vpFMP77N+yw/98QPOc/cdr8tkoc+ZOsCOid6HD1cEOA9oFQ+P6eaLD+vOxm+1d8WvnJBNT/dgoS9dPL3ssa2WbGtdn8/9n9/PqEXNb3KPk48q593P4+WCT63gwO+O7UKvJWHez/0tYi9rRmwPbPJDDwfeH4/oT4RPD6ANj60mRa9Hrd7Pwh5Gb8bNr++MdXJvjWGFj/4gRS9qdkxP5UB4L6P2xE/hrrKPkijSr7U1cQ9NjtkP3Zioj3XdZ29v3o2PPpqfj+otyK/j/iePkLAqD6CESA/w906vuypLb+rvgI/C8b9PjxFvz57ZQ0+wANmvR5haj90wlU8Jbj4PUUnrrxfBn4/0fpsP0jjIz61p6G8KS+vPjK8Cj+uG5S9Bfo/PX8DVj99vyG/11E2vR0ImD3ML0U/RdQPOc/cdr8skoc+1+wCOmZjcD+Lup++no0dPaPIDj7+fwU/Z0uAPgN3J74vkEw/NBUxv+VQPL7AUT++l0IsPyXODznP3Ha/LZKHPhbrAjqrfBw9oyPgPZgvPj//mCw/1UUZvjLqFr7zQTU/14KEvQjttC/LxBGxrXZ/P0Mlfz60Fia9j98fPCyydz+4NAk+9M3wveTbTLwS4Xs/y8+HvRKBoT1q8EI8iJ5+P8n8EjzDnDA+EgkBvTIGfD8IeRm/Fza/vjDVyb42hhY/xsoXvZDjMT/Y09++qN0RP167yj4No0q+b9bEPQc7ZD93YqI92HWdvR17Njz6an4/qLciv4n4nj5BwKg+ghEgP+i3Q776BC2/W2AEPwB2+j5vgb0+2YEMPnDSYr1xyGo/ye5TPD3V/D1n0a+88PV9P7LpbD8cECQ++NOhvBOBrz43/Qo/uM+TvXkWQD0E2lU/StYhvwBjNr3WNpg9dRxFP6bXDznP3Ha/LJKHPlHsAjrxVHA/u/KfvvXEHT1dTg8+A8IFP4AcgD7jqye+r2lMPzksMb/3eDy+D08/vl0oLD9f0g85z9x2vyyShz5m7AI67z2mO9Htcj16Q1s/aNMxP1cMwr0AG4m9ML81P+GChL02HAAx1T24Ma12fz+p9mi9o6gaO0/QnDy0iX8/JDOlPLlfKzu31508SOZ/P97dP70TBrM77f9BPHyyfz9Lk3C9XLC3u1vj5rzBc38/CHkZvxg2v74w1cm+NYYWP1Svkr4hbCw/0dz9vkBM7z7suI8+XqQvPenXoLtidXU/GRvZPWvr0Dv7UtK8p3d+P6i3Ir+O+J4+QcCoPoERID/9xZa+fkouv3Du7z65ofU+IQW8PnbrHb7JeH09bUhqPyEF7z0yJT87zWk3Pav9fT/qt3o/bOXFPU4zQ7y6VDU+Ylh/Pm0Q3b3kIeU8pUN2Pw90CL/NDfw82JjAPa0dVz942Q85z9x2vyyShz6a6wI6v+N7v0bsKT6km6e8y8h/PXxfOD7lE64+sTOIvXquaz9bOxy/3yJcvdr1M75PREU/JcUPOc/cdr8tkoc+OusCOi6CpjsH/3Y9TXJbPw5tMj9GfsG9MaqJvQkpNT/ggoS9ZTeasZcYHTKtdn8/9FhRvTGYFjuCiZE80Z9/PyyB1DzfIDQ7RZCSPDXffz9lKzi9r/aqOwfTOjyQuH8/dbvUvU5xn7p+kma86pZ+Pwh5Gb8YNr++MdXJvjWGFj/Tb4W+SpsrPzP4A7+Ffu4+kIiTPtGpOjwbtdo7UR51Pxsb2T2U69A7H1PSvKd3fj+ntyK/kPiePkPAqD6BESA/0ymQvtlmLL81E/8+n5nvPrrAwD61wAO+4otePYJ0aj8hBe89IiY/O7tpNz2r/X0/7pR6P+YAxz3YSkS8iAY4PhVwfT6yVN29bpXjPJBidj9PKAi/by/6PHR/wD2NTlc/TtgPOc/cdr8skoc+0usCOlYCfL8GMCg+juWlvLoCdD2QiDY+om6uPuAYh70ot2s/6v8bv5xsW72UezO+FHtFP9G5DznP3Ha/LZKHPnjrAjpaLqc7HqiAPfbpWz978DM/RhzAvTgbi72+qTM/24KEvT2j7TIJ7P8xrXZ/PynXGL1dwwg7h1JtPFfLfz8VzSI9SZ08O1NEbzzzxH8/JdgjvcaSlzulYig8Ysd/P4qXKL7/nhs8EAVRO1Z+fD8HeRm/GTa/vjPVyb41hhY/of9evlE6Kj/d9gq/gtHtPnBVmz4AMxq93izgPJqkcz8dG9k9QevQO/FS0rynd34/prciv5D4nj5EwKg+gREgPxsbhL6ULim/Et4KP+Nb5j4LaMo+2D+xvYvSLD3j2Wk/HwXvPTUmPzvCaTc9q/19PwM7ej+Yyck9FgpHvH3HPj6Wc3g+cwXevSqE3zw3snY/82MHvxQ79TzQPMA9lcxXP17ZDznQ3Ha/KpKHPh3sAjrcTHy/Kr4jPhiDobyjTFY92LUxPhdUrz5CJoS9P85rPzlkG785rFm9ckgyvvQIRj/qwg85z9x2vy2Shz6U6wI63SeoOxEMiD2Wl1w/rhU2P/Ewvr1nOY29n34xP9mChL1K6o8yan3AMa12fz9gtp28CV/cOqmJJzxW8H8/k75sPQnSLTu7LSk8to5/P9cWBb23dHo7im4NPHnafz/UjUm+ES3JPIa7VjwP5Ho/CHkZvxg2v74x1cm+NYYWP06fTb54rSk/1lANv1zD7T4j2qM+5BdzvTSqKD2z1HE/HRvZPWnr0Dv4UtK8p3d+P6i3Ir+Q+J4+QsCoPoIRID/C6n2+aOInv3v8Dj8+8uI+6CTUPrpKiL1jbh89QydoPygF7z3kJT87x2k3Pav9fT9wt3k/XLfNPQ/qSrwQQUg+t/BwPlEL373rWdk8ACd3Px5ABr/Cm+08Zte/PSSGWD862g85z9x2vyuShz4q7AI6DLB8v55CHT42Hpu8/CYsPWdkKj7LmrA+Lxp/vdfxaz91eBq/10hXvcyXML7N20Y/k7oPOc/cdr8skoc+CewCOu5VqTswxpA99mddP2eVOD+DBLy9us2PvfjlLj/agoS9inbIMbd7fzGtdn8/iwg4ulBHkjrVrsE7zf5/P81InD14mwA74PDDO5o/fz+TJry8Gdo8O8Ro2DsD7X8/UUtavuTHKj2ThaY8WdV5Pwh5Gb8ZNr++MNXJvjSGFj/SNVe+0fopP+AMDL8Txu0+8/apPkGDX72kPDU98c9wPxwb2T2d69A7/VLSvKd3fj+otyK/kPiePkHAqD6AESA/W9SBvqSZKL+jvQw/cc7kPvtI2j5O0I+9t3k1PTyXZj8jBe89ZCY/O8RpNz2r/X0/4hd5P8JI0j14a0+8BSxTPsiRZz66SuC9r5jRPFOzdz/02AS/l9bjPJdVvz2gZ1k/1dgPOdDcdr8qkoc+LewCOt0Zfb/tbRU+1GSTvIf69Tz5JCE+ixeyPsgZc73nHmw/8U4Zv8WmVL37oy6+y99HP1S4DznP3Ha/LJKHPpHrAjpKoqo77vCZPc1GXj8tKzs/B9i5vTGakr0MISw/2IKEvfDnczEO77cwrXZ/PzNGbjz/wQ06SqseO974fz85Zrs9iviJOr3xIDvU7H4/e7NDvHWI7zpqx4w7nfp/P/a9Mb57+nU9/q6nPB6Xez8IeRm/Gja/vjLVyb41hhY/tM9ovuyHKj/qjQm/qODtPklSqj7gGR29sf0dPaQEcT8dG9k9oOvQO+dS0rynd34/p7civ5H4nj5CwKg+gREgP+bwhr5G5ym/iXcIP1ZS6D4F6Nk+/+asvfXLUD0UR2Y/HwXvPR0mPzvJaTc9q/19PwhueD+A8tY97QRUvKcyXj4w4lw+E67hvUisyDwZTHg/s0cDvxuV2Dz2wb49uV9aP7bXDznP3Ha/LJKHPijsAjqwfH2/sugMPk/9irzG1pA8kYAWPrmjsz7M0mS9flJsPy76F7+ABlK9L6UsvrkBST/Uvw85z9x2vy2Shz4I6wI6BvKrOxSnoj1tHl8/dpY9PxPit71wWJW9/HQpP9qChL3cU+cxhjK/MK12fz9c47k8FNhKOVv9Fzod738/FwTMPVIS6DnQgRs6/7l+P87CljjcoTE6S6TpOuL/fz8kyqa93aqcPRH7RDzcYH4/CHkZvxo2v74y1cm+NIYWP7SXfb7MLSs/u0oGvy4p7j4lqKQ+CoJqvP3b1DwVSHI/HhvZPYbr0Dv7UtK8p3d+P6i3Ir+Q+J4+QsCoPoERID/XsYy+8mwrv8kkAz+vqOw+2xjTPh5e2L2HOWg9KDNnPyIF7z2gJj87wmk3Pav9fT8/y3c/VkLbPb9FWLzfQmg+B+xRPjER473kb7881uB4P0azAb/a78w8cCm+PbxVWz/I1w85z9x2vyyShz4z7AI6wM99v7ZzBD7SpYK8+XXNO3hQCz7HGLU+u1lVvYaHbD8jlha/1plPvYnOKr5+KEo/fMAPOc/cdr8tkoc+cOoCOrAgrTuqBKo9vtdfP8maPz9zTra9Z7qXvaMqJz/bgoS9dhe+Mf5omrCtdn8/ySnGPGdYBDmBiX850+x/P94Rzz1nsac5YXeEOSewfj9A3Qg8sqvyuGKwIji3/X8/Re7YvN4Hsz0ujVU7su1+Pwl5Gb8ZNr++L9XJvjaGFj+0jYi+gMkrP47hAr8CnO4+s9qbPtycQjw/Fz08ctBzPx8b2T1S69A7D1PSvKd3fj+otyK/jfiePkDAqD6CESA/N82RvsHWLL8xrfs+cvDwPokzyT6OXwO+7uN2PWCXaD8tBe892SY/O79pNz2r/X0/AUJ3P/PL3j0Iw1u80WdwPt/uRz4fTeS99/K2PGNheT+6SAC/PlPCPImevT3ULlw/UdgPOc/cdr8skoc+0OsCOoUOfr8b5fk9pn12vCQ8SLuf1gA+zVG2Pk1+Rr1Wt2w/BEsVv+yKTb0lTSm+wzNLP+G5DznP3Ha/LZKHPv7qAjpoAK47JSevPZ5aYD/K/kA/tUC1vV5smb2BjSU/24KEvV3+8jGuXCywrXZ/P4wqxjySVgQ5zm1/OdLsfz+jEc89YrCnOXp9hDkosH4/mVsePCf5fLnf4nm58Px/P3CWAbzyy789HzUQu8Ldfj8IeRm/Gza/vjLVyb41hhY/lr+Pvso8LD99HwC/bhLvPkWUkz6/+wg9pdFJtz38dD8bG9k9sOvQO9dS0rynd34/qLciv474nj5BwKg+gREgP4xelb4d3y2/cGvzPhk+9D5AK8A+SvIVvv+mfD2KxWk/IwXvPZolPzvPaTc9q/19P2Dkdj+6KuE9iRlevIHMdT66ZkA+GzflvWSBsDzrvXk/6Xf+vqpxujyXOL09oc1cP6nWDznP3Ha/LJKHPvXrAjq2Nn4/f/LuvTqxazy76hg8rLbxPcoqtz4J9zq9MNpsP0pQFL+dEEy9JUgovgf6Sz8juQ85z9x2vy2Shz7U6gI6qluuO+sssT2NjmA/JIpBPyrZtL1aGZq9xOkkP+WChL0ZDQCyshiJL612fz/3KcY85FkEOcBifznT7H8/2hHPPVuxpzlffYQ5J7B+P8BbHjxg/Hy5G9t5ufD8fz9UR6G7LYnEPb8chLs00H4/CHkZvxs2v74w1cm+NYYWP1evkr4gbCw/z9z9vkFM7z7puI8+X6QvPefXoLtidXU/GxvZPTbr0DvmUtK8p3d+P6i3Ir+R+J4+QsCoPoARID/6xZa+fkouv27u7z66ofU+HwW8PnfrHb68eH09bkhqPyEF7z0aJj8702k3Pav9fT+sv3Y/phbiPTACX7zw4Hc+1Vc9PvWU5b364K08bOJ5P+Ge/b7cPbc85Q69PT8NXT+F1Q85z9x2vyyShz5d7AI66EV+P2p86r3GSmc8kUZAPB0E6z1rgLc+LRQ2vWLobD+j5xO/SHVLvXXjJ76+S0w/68sPOc/cdr8skoc+uOoCOlJ7PztymrA9jotgPzUxQT8ShrS9rXqavetRJT/fgoS9uuvvq4dQwK+tdn8/ORfXOzK0/zjouIQ5lv5/P9ceqz2+GaA5WFOJOdQafz94kN88mqJzuZEfgbmX538/P6ZEvJm3xD2ntQc4O8x+Pwl5Gb8XNr++L9XJvjWGFj8vLZm+B4wrPzAZAL+LOes+0RF7PucsnT1BvUK8a2N3Pxsb2T3R69A72FLSvKd3fj+otyK/jfiePj/AqD6CESA/STuKvjmTLr8nqfM+zIP4Pn3iuD7mV2i+sHa6PU1gZj8ZBe89UyU/O79pNz2r/X0/gPh2P/og5D11BWG8jNVzPr1VOj5ui+W9IP2qPDoHej/nCP2+AfqyPGbuvz0sL10/hdUPOc/cdr8skoc+XewCOl+vfD/M0hq+37aYPL6+TT1l3lI+2mewPnE+n70poGk/6mMTv23FhL1QJSO+F6FMPzHrJzk5c3O/hVeePhobATriz7I8lDYxPlW7Tj87lkk/svskvlZA9L1BNxU/3oKEveWCn7GkvyEyrXZ/P5anj7xB5Q87LsLcucP1fz+jx3M9JR7aO0Yugrlfin8/q2lSPb8okLtg5x0606h/P9Y5qr5HO649h2sRPeJHcD8IeRm/Gja/vjDVyb41hhY/dhLMvrm3MD9l+LG+NM38PiJcHT8hNa49kzxrvWw1SD/f17U9DleSPbhWMT0cF34/qLciv5H4nj5BwKg+gREgP8txNL7SRje/ViK0PrmkEz9mLCA/mLpjvsghRT7j9Tg/DlEFPjFBoL1jTHw8rP98P3PIYD9wX24+JyDrvHmS1T43UMg+TiZ+vi4N4j0mGWE/VY8Ivy/ixz2Rpdo9W1hVP9fZDznP3Ha/LJKHPlLsAjo3m2o/W8yEvkb9Aj1sLZs++KryPs8fmT4gNjO+WDtPP+g0JL+CICu+IsQGvpWyPD+v6ic5OHNzv4pXnj4hGwE6ZCEiPQzoLz7kbjw/JZdFP9qOUb6w/R2+8/UUP9yChL3Pp+cxnAeyL612fz/f8M08shKJPGHGEbyE338/u/nQPcSbVD2Y2fe7PE9+P/f7CzytZwq9YRAdPCvVfz+gEkK+F4R9PRIMxTzoyHo/CHkZvxo2v74z1cm+NYYWP19nwr7dBDI/ixqvvuBZAT+e8EQ/iDd7PfnBgL3gACI/vclXPQzOoT1nvnW9QmF+P6i3Ir+P+J4+Q8CoPoIRID8IKQC+TUA4v7yNpT4h+hk/UTctP/4YBL46Dvo96u42P+yx2j2ObeO99ORoPOPqfD9sWVU/CkKSPgBEEL3BkfE+gmYKPyx5Wb5GrBI+3SJNP8nEGb8cDD09I8jCPVLgSj+Q1g85z9x2vyyShz647AI6sFVfP6+ilL5QnBI9LIHIPvydGT8rRmA+IX8zvj7IPz/BmS2/kXoyviazBb40sjM/Q+8nOTlzc7+HV54+hRsBOiIjTz343C0+Jd0xP/SsQD+7B1e+QbwrvizhGT/cgoS9TntoMjhVYbCtdn8/+AKoPQUIYzwn6UC8Ohh/P7xWIj7PXjM9zZguvMF/fD8AYka9X7HmvNWkPDy3lH8/AGUKPcSikT206g46kTR/Pwd5Gb8XNr++MtXJvjaGFj9Zc62+BI0yP0iNvr4NmgI/JD9LP1FjqDz0ZXK8t4MbP6MAqjyL76U91tgQvhOFfD+otyK/jPiePkLAqD6DESA/m96mvTs+Nr/aULs+lAoYPwolMT8yfRW9O6MPPaZbOD8sJrQ9UwAJvjE+VTzWrHw/tf1RP6v1lj4w5xS9Wj/6Pnr6Gj/Eizm+5HYTPhr0Qj81TCC/PGDaPMu8uD27JEY/0tYPOc/cdr8skoc+desCOjAUXD8V6ZK+xugQPSeg1z61nig/DCAnPrsRGb7oGTg/TbcyvzvgFr67bgi+FhkwPxjmJzk5c3O/ileePogbATrbq1g9tAQ7Ptn5LD85hjc/OKBLvmXONL5D/CQ/2YKEvYkH47JuLZAxrXZ/P2SECj6HwtQ7xFX1u2OifT/KPFg+S7SqPHX547vyKXo/WwUKvuLVXLxbMtY7i6J9P6++Sz5qhqM9sKXSvPD1eT885hm/geTEvnTx1L5bTRA/oD55vkRpND/5gMq+jk4JP7wNNz9WODG9kxFSPbgiMj/OPRq7oiXjPHsFv73RyH4/vVojv8yEpz5547Q+tM0ZP4R8MzsjXy2/Swb7PppxDD8U1Cg/K/FJPda1Mb0ltD8/EoLdPWHQUL5bopc8owp5PxKIVj9gJ4U+A1cDvccM9T7huyA/FL38vUBL0D3B/0I/16EkvzVmq7z0oLM9eq1CP3rZDznP3Ha/K5KHPqjrAjpLgl0/BO2WvsDeFD1cxc4+ju0vP8KPFz76phW+ZS8yP+gMLr/6eyC+K/75vdy1ND+R7zU5ijNxv3WOqz4wzf856/EYPTqnjD55dRw/GUYmP1oLKL6ZTyW+CoQ5P9aChL3ek5oyZyyzMK12fz+FsSs+Vw1rOm2EbbosYHw/dO14Pm/BOTvDf1q60VF4P6EnYr5L+va6/twoOpOteT8ZEis90h6+PSJwkrwLoX4/NAUav8j7zL6fh+e+ztEFPwiedr3+GzI/GQPivmI9ED/QyBA/eDqwvWYWdz09Z1E/eDwbvCn1or2Upka8bSh/P4NhH7+X4b8+v6nXPgbuCj+7+Qw+OP4VvwVLKT8lOeU+bNYDP+JoPD7Cl+i9oVhUP5MPDD4ekIy+/1WKPEefcz9W1Vc/dwNpPu3W5by4Dfk+7qIkP+s2X73jPjw9wy9DPynUG7+xwDq9HqfUPRoGST9P1Q85z9x2vy6Shz6l7AI6es5ZPxWcmb50hBc9zBHcPpcbRD+qZv49c3ofvnRzHD/D5CW/WcgPvhwQWL0cKD8/Q4BPOZWXbL9YjcM+yvb6OQpQNzwUxf0+EvG1Pso7BD/l6gK+ThnJvbJIVz/ogoS9kdJvNDhHCratdn8/WEQvPkLexjsG4Ee7YDd8P4R3fD6REyk7/N2SOLEYeD8Idm6+FaaYuacoSLk99ng/ayY/vs57xD1WnHw70Ut6P7f4Gb9GIs6+q4nqvhAdBD876b895/IdP2kWHr/gHvU+51ARP2R6b76VjjI+lxVFP6w/uDwqpg6+0NEVvfJDfT9czgy//27nPrcU/T5hZf8++/LKPqfSCr+rNgs/FsoAP/IDaz7NWdA+71zZvf+0YD8HPJU9raDvvQ+DfL2PEH0/dIBSP6Fzjz7Cfw295v/8Poi2/z6o2i++tKrJPe/qVz/u2bK+QK+APFibIz5uU2w/Db0POc/cdr8vkoc+huoCOp2ANj/HUqK+8RsgPTHRHz+HkFk/sRcDPgLhd76ZiuY++jYav9GlYb2QDqE9i9pKP0U3STkAxm2/+Lu9Phgx/DlqMOo7DX0OPw5mjT0Myl4+taj3vdYKqryv4nc/5YKEvXwg+TVe+DO2rXZ/PwUiHD4kMRk8NnKWuyH+fD9IpWk+nTxyOw9P7jfLPnk/UJVbvrCWfbn/6wm5fgt6P029Tz7ByYk9qnuxvNEFej8SvB+/zNm5vn+9zL7flhA/tB4svsyXMz+CK9u+0VwLP9rpQj8t5lS+XYeTPqDRCj8Lrs28BlG4vtmA6Lyuo24/xKX2vjMi/z62Ys4+1fwYP4HXJD+pq9y+NbvHPnWv/j4fmCA+BA0IPyLS0b1yfFM/qV+qPcm6wT7htK28APJrP3mxcT9Rij0+9fi6vCcniz4UT1E+E26qvv3Vlz1V5Wo/RR+Zvij9HrwP9d89TqlyPxu9DznP3Ha/LpKHPnTuAjqhGk0/uUwhvk4XnzwjtRM/YGQpP44uID4kJRW+ufo3P4b0DL9wdPw80jAKPsC9Uj8Y9yc5OnNzv4FXnj7nGwE6hXq5O0+3DD8N9b09tM7rPL2X7r3z+467xiV+P9uChL1Btusyrng1sq12fz8U/289e6uIOZb3Rrloj38/ZckKPkxDILr7+zo6QKN9PwJZA778xhA62DQCup3ifT8PcuE9SnncOUSiILqycX4/NVMov3WeaL53mXC+DcotP/IqUT73Ui0/RCwevjCgMD/QcSI/dYOUvnAajj5yEik/Q9YevkMPH7/i1iW9mVhEPxpy+77w+MM+Sb14PrBsPj9JgB4/4Un1vjXkTT4/vRY/plOcvLpl0T7ajRS+p5ZmP1N4hD2g+R8/M2CtuworRz8d6nY/WF0qPlELqLxS6FA+9DIFPgXnrr7MmEM9dPhtP30vjL51Tca7BIcAPlsbdD+xyg850Nx2vyuShz7G6AI60JJkPwy6dDqFcfG4wpDmPqk9ED/2uOm8pYafPKVPUz80aw2/wBSEPieroT2N6Ek/mv0nOTlzc7+GV54+6hsBOrXjFTzq9gs/+ix8PbHysj0pCQC+2yo8u8cAfT8Vg4S93laSNnvzqbatdn8/f2CbPMqEZDvOTH27U/N/P2JpzD0kTyO8zUY2PGaxfj9Rikq+LzAbPPnA1LvZ7Ho/s0oJvp0PKDwZN6m776t9PzRTKL94nmi+d5lwvg7KLT9fjy4+ALUvPzyVQr5jVS4/SMPePpDVDb9l2xE/abHYPvTC0b0yz6m+LgaIPIkLcD8ecvu+8PjDPkq9eD6vbD4/fwWDPuTpJ7/r3W49Ry41P2fc0DwC9Kc+s8Eivi1Mbj8fPxY9sroaPw1N0bx6oEs/HAN4P1+uCz7vz4m8vzRTPmKnMTwx48e+S92TO1yqaz/WYY6+7CAcPZQwyT0Ba3Q/hscPOc/cdr8rkoc+xekCOlvJWj+RW088gOzMuvXhBD9pEOA+Lb1AOpghnbkqL2Y/wQrqvh2OcD6a49s9PuBZP5HxJzk5c3O/hleePl8aATozqBY8wNELP1WQcz3B8849RCnqvQRcersMAH0/84KEvRl5JTYrVUq2rXZ/PxSKGT39NrK7Ivo8u7PQfz+6HvI9XuRzvE17ZjyPJn4/JFN2vkWhOzxUbgS8/nR4P6Zueb3xN0Q84qzuu+x/fz81Uyi/eZ5ovnqZcL4Nyi0/eloWPnL7MD+MBWm+4HsrP3mMvD7myxe/G/kfP/oMsz5CQoC99f5ovnhd1b3PVXc/HHL7vu74wz5NvXg+sGw+P8VDiD5Lkya/w2YjPYfGNT/vTo08iFy0PuagIL7aKGw/P+SCvOo1IT9Gr6G97cpFP7rnez9opQk+VsqHvEn/7D0tLxE+GuaXvo63Nj29fnE/RjH4vpdOB70KqY09qAxfP9a9DznP3Ha/LZKHPifpAjpihGo/B20JvWt8hztxk8w+dq61PkpIfj2agcG8YrxuP0x04b6aVSg+ROfMPb2AYD9Y0Sc5OXNzv4VXnj5vGwE6y28UPLbSCz/KHYA9JWDPPUC26L2iuIe77AN9P/qChL3x1xg2ilI/tq12fz9IaQw9ZefDu2p7Ibsd2H8/4S/sPYHLeLzhRGM8xjx+Pw9cc77OWTw8bEMDvLyjeD+dI3u9/0FFPAXo6rtBfn8/NFMov3WeaL53mXC+DcotPz3JED57VDE/wshmvvOcKz/qKL4+OIkXv2nvHj9n57U+JcWKvTcTar4WiQu+dSh2Pxxy+77u+MM+S714PrBsPj+KBWw+wxQpv0VU1TzE0DY/lDQ2vAMeuD573CG+w2drP1iM3bxrQSc/pfbFveAYQD+FQnw/+04APhsofbzsHOo9h08PPpY0d757MxA9eqp1P7IK0r57U7y9t3FqPWTQZz+hyA85z9x2vy2Shz4y7AI6iPJ2P1Wpsb3TNC88jaF+PtSblT5DLiY+wm5OvWTucD+gT9++GulhPR8jsj122mQ/bdEnOTlzc7+IV54+px8BOtORJTy+0As/tXGAPQLuzj3n0gG+KFQXu92cfD/ggoS907G6s5BqSzKtdn8/r1HzPBh0fjvADaq7teF/PwnL4z0lqEK8tdllPDVefj+PIm++Ll49PM6YAbxK5Xg/Y9zBvXxfSjyaVdi7R9N+PzRTKL95nmi+eJlwvg3KLT/bDBA+K2cxPxpFY76K3is/BWG/PuwrF7+rnh4/vO+2Puxmeb0izle+vQa2vdS5eD8ecvu+7/jDPlC9eD6vbD4/9ENxPn99KL+pCqM80vs2Px5M1DsSCbk+MEIkvv0haz/Xzcq8POcjP1LJxL35AEM/jzt8PzuyET7stY+8S6G+PVSSDD58qca+cNdvPWHUaD/AWM++x7+CPeFRzj1vEWg/dLUPOc/cdr8skoc+SOkCOn7Gdj9qB8a9SlVDPNB7fT6x1pQ+cNpGPkBbd70HWW8/JvDgvqfFCTwP6KM96QtlP/bXJzk5c3O/iFeePmAfAToiMiM8NNELPzJYgD1kHs89iwsAvj/nKLu6qnw/3YKEvR06gzK9b0cyrXZ/Pzao3DxPFCg7umCeuz7nfz8IRd496H9LvEwBZDxrcX4/gmtsvskDPjzmhQC8yA55P6wJ+b28AE48/tzJuzITfj80Uyi/d55ovnqZcL4Nyi0/rxURPoRbMT8OcmG+EgMsP7LqwD5YuRa/xygePzpjuD6CKVi9PqUzvrhyzTuHqXs/GnL7vu/4wz5NvXg+sGw+PwXddD6OISi/dkSOPEEINz+jVeo74Q+3PrM6JL7EhGs/5c3KvDznIz9PycS9+QBDP5wxfD+nhRI+soaQvIFZvz0i2Qw+OBnIvshkcj1HgGg/Kh/Pvjh6jD0LuNA99/5nPyG3DznP3Ha/K5KHPhvoAjoBzHY/leTFvXoyQzzJLH0+cM+UPn7ZRj7NTHe9Q1pvPybu4L7o2yY8fU+kPQkKZT8AzSc5OXNzv4hXnj4CGgE6IjIjPDTRCz8yWIA9ZB7PPYsLAL4/5yi7uqp8P92ChL0dOoMyvW9HMq12fz9ppNs8QAooO21unrt2538/aATePayPS7xQ9WM8TXJ+P99LbL52Cz48q3kAvKgQeT+Vvvu92StOPPwnybuGCH4/NVMov3ieaL5zmXC+DcotP+EhET74WjE/5lxhvrkELD9M/cA+6bMWvx8jHj/sdLg+DGJXvfELMr4v0yw8+rl7Pxxy+77w+MM+Rr14PrBsPj+6NHU+5BEov2dyhTz2EDc/BnzrO4L1tj5EOiS+5IlrPwjOyrw85yM/R8nEvfkAQz+cMXw/p4USPrKGkLyBWb89ItkMPjgZyL7IZHI9R4BoPyofz744eow9C7jQPff+Zz8htw85z9x2vyuShz4b6AI6Acx2P5Xkxb16MkM8ySx9PnDPlD5+2UY+zUx3vUNabz8m7uC+6NsmPH1PpD0JCmU/AM0nOTlzc7+IV54+AhoBOiIyIzw00Qs/MliAPWQezz2LCwC+P+cou7qqfD/dgoS9HTqDMr1vRzKtdn8/aaTbPEAKKDttbp67dud/P2gE3j2sj0u8UPVjPE1yfj/fS2y+dgs+PKt5ALyoEHk/lb77vdkrTjz8J8m7hgh+PzVTKL94nmi+c5lwvg3KLT/hIRE++FoxP+ZcYb65BCw/TP3APumzFr8fIx4/7HS4PgxiV73xCzK+L9MsPPq5ez8ccvu+8PjDPka9eD6wbD4/YkB1Pk8QKL/CxoQ8jxE3P3e16ztT8LY+KDokvuaKaz/+zcq8POcjP03JxL35AEM/nDF8P6eFEj6yhpC8gVm/PSLZDD44Gci+yGRyPUeAaD8qH8++OHqMPQu40D33/mc/IbcPOc/cdr8rkoc+G+gCOgHMdj+V5MW9ejJDPMksfT5wz5Q+ftlGPs1Md71DWm8/Ju7gvujbJjx9T6Q9CQplPwDNJzk5c3O/iFeePgIaAToiMiM8NNELPzJYgD1kHs89iwsAvj/nKLu6qnw/3YKEvR06gzK9b0cyrXZ/P2mk2zxACig7bW6eu3bnfz9oBN49rI9LvFD1YzxNcn4/30tsvnYLPjyreQC8qBB5P5W++73ZK048/CfJu4YIfj81Uyi/eJ5ovnOZcL4Nyi0/4SERPvhaMT/mXGG+uQQsP0z9wD7psxa/HyMeP+x0uD4MYle98Qsyvi/TLDz6uXs/HHL7vvD4wz5GvXg+sGw+P2JAdT5PECi/wsaEPI8RNz93tes7U/C2Pig6JL7mims//s3KvDznIz9NycS9+QBDP5wxfD+nhRI+soaQvIFZvz0i2Qw+OBnIvshkcj1HgGg/Kh/Pvjh6jD0LuNA99/5nPyG3DznP3Ha/K5KHPhvoAjoBzHY/leTFvXoyQzzJLH0+cM+UPn7ZRj7NTHe9Q1pvPybu4L7o2yY8fU+kPQkKZT8AzSc5OXNzv4hXnj4CGgE6IjIjPDTRCz8yWIA9ZB7PPYsLAL4/5yi7uqp8P92ChL0dOoMyvW9HMq12fz9ppNs8QAooO21unrt2538/aATePayPS7xQ9WM8TXJ+P99LbL52Cz48q3kAvKgQeT+Vvvu92StOPPwnybuGCH4/NVMov3ieaL5zmXC+DcotP+EhET74WjE/5lxhvrkELD9M/cA+6bMWvx8jHj/sdLg+DGJXvfELMr4v0yw8+rl7Pxxy+77w+MM+Rr14PrBsPj9iQHU+TxAov8LGhDyPETc/d7XrO1Pwtj4oOiS+5oprP/7Nyrw85yM/TcnEvfkAQz+cMXw/p4USPrKGkLyBWb89ItkMPjgZyL7IZHI9R4BoPyofz744eow9C7jQPff+Zz8htw85z9x2vyuShz4b6AI6Acx2P5Xkxb16MkM8ySx9PnDPlD5+2UY+zUx3vUNabz8m7uC+6NsmPH1PpD0JCmU/AM0nOTlzc7+IV54+AhoBOuRfmjzOs2c9LyJUP+SkUT8atQC9WRcWPSFmEj/hgoS9vgEDsgDfJbKtdn8/utzZPUZYrj0554u9VQJ9Pw9yKz4Tq44+ICPNPMcCcj8S5oi9KxY/viXaHLtu63o/SLb+vUvvPL6mneU8oHp5PyoEHr8TRaS+kdCpvlQhIz/soDe+cJQ1P66Vx76KLA8/wmIjP6bN2T2a6O283QxDPyUF7z0MJD+70Gk3vav9fT8XoRq/VrGwPrSjtj4HoR8/07cpO/DlKr8ewgU/dskHP0+bMD/+DJE+qs92vlT+Hj9bMkM+6EUgvczROj2l1Xo/0nJiP2/XSr0YFMg7gG/tPuIYLTs5KqC6bp/Vtrn/fz+JFvq+4kq+PF50Pz2r+14/g7sPOc/cdr8tkoc+QuwCOp66e78qgSw9rSequ3YhNT5cXdY+XBoavKrBjTuQd2g/OpLXvp8GtjzBnDa8qR1oPwzYDznP3Ha/LZKHPlPsAjpmbZc8jizBPeK+Oz8mxkY/S0fPvBsSKT1y2CA/2oKEvWtaczJWvayxrXZ/P26jBz4vP6c9tfijvbAMfD9CekY+/8SPPv8UOzy0nnA/j3HBvZP7P74Luww8HUl6P8iedL2JNyu+D7RtPYR+ez8rBB6/E0WkvpLQqb5TISM/u1AzvjwzMj/NZOa+fQQIP8K/Cz8I6aw9Su1uvLtdVT+jrNE9Q4SkO19tDT2Ef34/yJ8bv+YprT4M/7I+TKggP2+WyT0nbya/G2wHP1JWCT90Kx8/CMaePi5hfb5K4Cw/sF01PuWwGr2Ekjs9eH57Px37TT8lzYm8d+wHO2fzFz8oncM+ecOHvSIZ7zwD2ms/4br1vrm1hD3qgys9ArhfP7LFDznP3Ha/LpKHPrjqAjpRx30/0G05vQ/ntjs6fPw9D00oP/d/bLxvc1I8ZtZAP+6DN79Zm6Y80AVBvBFjMj9Zxg85z9x2vyyShz6u6AI6CeGQPHpBFj49TQQ/LZopP76IH7xsK0k9OVQ/P9+ChL2c2g+y2REMMa12fz8SxjM+Q2eXPTH1yL3IDXo/ws5yPnx+kD58kzi84fRtP1knD77paUC+F9DcPMnIeD8sLrA9dcHvvTyfyz2CAHw/KgQevxNFpL6R0Km+VCEjP3+UIr7SwSk/s4MOvx7z8j4vvLY+PdL2PJF5ATveA28/IYKePYLkkTvvvDg+JAR7P8/BHb9pQ6U+IteqPrzcIj9KaYI+seMcv11JAz+yZws/+vnvPqD0uj66aWy++z9FPxaTFj53gQ69AOU9PTXIfD8KZkM/NybTPedFULwhPiM/aSYfP8Y0Kb6riQ4+/rxAP8SB0r6duwM+WtW0O5sFZz9yxA850Nx2vyuShz4u6gI69ENOP0BLIb3cGJ87LEkXP9gzRz8Tz7G85zbcPKmMID8v1DG/YoqMOqMaC7w8JDg/t8YPOc/cdr8ukoc+veoCOp67iTysSQI+WQSIPm3P/z4h6CY8/4RYPR9UXT/XgoS9RGwxsWlxzTGtdn8/OwhGPrdvhz3nzNG9Tzh5P/BKgj4xr48+n7GlvMzcbD9+liG+AzhAvsK+DD3yBng/s8l4Pm2Lfb1LpM894HV2PyoEHr8SRaS+kdCpvlQhIz8VchG+tEsjPxcbHr/OD+A+ck9wPmoAI7xtljo7LtZ4PzaCkT0eLtK8MD+JPiTfdT9T+h+/wH2cPsjIoT51KCU/aFecPjVOGr+bXvg+ZhoOP3CSpT5NfsU+AZcpvo0aWT/YU+k9W34BvTtyQT2q6n0/Th05P7/Tkz4v0BG9xmEgPyLwRD8to02+wv2VPtn0Bz9a8M++38QxPuF8ob2hyWQ/gcQPOc/cdr8tkoc+5OoCOil8Zz+GREq9KoPHOzYm2T5Zz9E9JqCKu4DXATt3pn4/ayWcvdth4b1IXIy8Tah9P+XLDznP3Ha/LpKHPiftAjo6KoU84P1aPFOrtT2KqKo+hLrXPFz+Tz186nA/2oKEvbV+BDGpu6mxrXZ/P7ydST5RNXs9I7DNvaQseT/1M4M+s9uOPuaKrbw522w//I0jvvAuQL6HABA94vB3P/b0nD5VP/681KmIPeDxcj8rBB6/EkWkvo/Qqb5UISM/0a/HvY2MMz8S6Nm+pzwQPxI/Bj/qY7I9WftVvLnOWD/CUKU+/TMZvkr1lDxeMm8/FGAhv4Kklj4Nv5s+UJomP/Y3UD7dJyW/6YfpPiUKFD81UX0+fomWPhnQrr3BVWs/f2+8PWRG8rxhXkQ9gYF+Pw9nIj/S6/I+mpxvvXaDGz86PVo/i6gSvotfzD4iepw+UQ7LvuW9Oz44oCu+PD1iP+rCDznP3Ha/K5KHPtnpAjrfbmc/HdI7vRNDuTt2k9k+agCCPvHK/LsGEAY7GZp3P8x4s73SKg++B7n6vIxefD8YyA85z9x2vzCShz546wI6z+GCPOTk1LxAL9M9Z2oSPieusDySZSQ92Rl9P9qChL3x+8WvxlJgsa12fz+Xk4E+b5WSPS6ta704jHY/Sm84PgPJjD68uj28mcFxPz2O0L11FjO+7Y3cus6zej99ysA+5koHvaZ05jzT5Ww/KwQevxVFpL6R0Km+UyEjPx+/8T39vjI/ej1dvvQVLD9M/0c/dwYqPqEKIr7anxQ/3wOCPsmk071HLGO8aCp2P4QIIL+5Npk+FVqaPuShJz/k1u88dDQ0v6Tsrz4U9h4/5AhuPgcR7T35I+S8aB13P+uKyz08Iga9ZO+dPPWLfj8nDEE/pZC5PokJN704vws//FlmP4TCu70jmXM+0ES1PkiPCL9DkxY+AvvmvS9GUz8AxQ85z9x2vy2Shz426QI6ltpzP0KrBL2V3II7UPCaPrVQyT4t0ve7hMtSOwpfaz8mP3S+uAMXvlpy+bymmnU/EacmOXqlc78kIZ0+5jQBOh8InTycr7y8HKO7PXhgIz6MX4s7vAMuPfZ7fD/ZgoS9C9ucsLBniy6tdn8/00c0PmhxrD1LZ1W9KLl6P1VMGT5Ij40+mGthPOr9cj8UbG29FNApvkwC1bxW7ns/7trAPn0FA72DPSW8TP1sPyoEHr8URaS+k9CpvlQhIz81DR4+7rUwPz68S74Hpi0/MCNDP8zZZz5m6o6+Qs8JP+FrFj41jc+84MAmvdnsfD/CriC/NZWXPgYlmj7ubSc/J/ndvFOwOL/kwF4+LCgoP+1jez7QpDo9CGY9vKjfdz9FI9k9nV5XvaKHbLlwM34/8rVBP3Bqgj6UowC96u4ZP1jfZD/i1KC9jhUxPka+zz7yjha/0ZRPPS/wir2H6E0/0sUPOdDcdr8rkoc+LuoCOmlRbz88ERC91RqOO6PktD4OjuI+vXoZvMmtlzv0jmU/j4iZviR1Kb7sZRO9A1dwP5JXbDnpeWa/SdzePshw9DlEt6g8P/MsvLQ4Zj3cBJQ+sJMCu/qMRT29wXQ/3oKEvepoqrGpgQuyrXZ/P/e04z3OOK496syQvfXUfD/zVzA+GP+OPn/AuDwkwnE/kjqTveVJP758UNG5wNF6P05zCz6imAq786hzvScofT8rBB6/E0WkvpTQqb5UISM/wdV1vUQiNz/R4am+tawcP+BkPD/zyzg+Iu0wvlgZIT8jBe89riM/u81pN72r/X0/GLghvxcplT5UN5o+UfUmP+KUcL1W6ji/L7aEPgVxIz+EHpA+YxOBPYf5l7yREnU/nz/APY5boL1hnhY93Od9P5dCJz9nDa4+ca4rvVXVLD9wq1w/orQGvrbGkT4x58s+NfMNv2yfpD0dIdW9LF1SP1rNDznP3Ha/MJKHPozqAjqJtGc/LbcVvQutkzui4tg+0byWPjEq57utlxA7iaV0P98RRb4lWi++WMtCvWcPdz8K1IA5zFthvyDl8j5LAe85ur6fPL3XLby61k09c2yOPmAAvbp+oUU925V1P9yChL3GJkSxxzrnsa12fz9AuiE+R1SsPVgewb1BtXo/+gpgPv2LkT6+eA67GvZuPx8m+L28ZkC+QpCePIJ4eT9rcCc+eaLFu0C6Sr1RO3w/LAQevxRFpL6Q0Km+UiEjP1MjJ76BBDY/CbLDvlk1ET+ZfkE/8n8HPmHkrr2HsiI/IgXvPZskP7vDaTe9q/19Pxm4Ib8aKZU+VjeaPlD1Jj9ExtC9ik84v48moT4LLhw/aFyxPotWsz2IWAW9o/RuP6I/wD1+W6C9Zp4WPdznfT8oQis/FMrUPgPkUb17NR0/ZvFUP/zxK772Rrk+7ZnFPl0pC7+jvRg+uwsRvtJRUD+ayg85z9x2vzCShz7n6gI6QwNwP1uSEr00k5A7/SOxPkuAGT5CkXe7Sq4TOgEbfT/6ROK9UuMrvqu8Zr3ZXHo/zdGAOcxbYb8f5fI+4wbvOZxMmzzIgji8ytRGPdU7hz7qM0G6M7JFPXKZdj/WgoS9dY0Ash7pAbGtdn8/xfdBPsxVqj2dSOK9Edx4P0UcgD7impI+fVKevLC3bD9FRR6+mkVAvglDBz2NK3g/KASUPrNgQ7zyRSm9TNJ0PysEHr8URaS+k9CpvlMhIz/toDe+cZQ1P7OVx76ILA8/IPZBPwKkzD1wxD69SK0kPyYF7z0uJD+7ymk3vav9fT8YuCG/FimVPlY3mj5R9SY/MLf7vUKhN79StK4+GU0YP2ta1z5WNsg9sQs7ve6aZj+VP8A9hlugvW6eFj3c530/zxAvP+Mi5D5FB2G9nzwTP9wMUT+ntzu+p4zJPsWwwj4GuAm/Wl48PhECJL6gkU4/SMYPOc/cdr8wkoc++eoCOhm+cT8e1xK9DteQO7V2pz7QDw0+Xcdmu1K0+znHjn0/s33Tvda7Kr4Zkmm9gpp6P/PPgDnMW2G/HeXyPmID7znrf5o8qjc7vLcDRj19joU+UTIWuoe0RT3q03Y/2YKEvdS2qLAjKU0xrXZ/P8iDSD5d2qk9WxTpvS9xeD9sYYM+xL+SPopDu7zbOWw/Pzwlvp4mQL6xyRI90t13P+VNwT7xiHy8aEwevWjQbD8rBB6/EUWkvpHQqb5TISM/6qA3vnKUNT+0lce+hywPP2heQz9P0Ms9a0ZCvTYBIz8kBe89EyQ/u8NpN72r/X0/GLghvxcplT5VN5o+UPUmPweuAb5Jeze/JRqxPuWVFz+7FPY+9C7GPb4AW72as14/lD/APYZboL1snhY93Od9P8DgLz+pleY+f3FjvbJJET+TYFA/r04+vp0rzD5dN8I+u3QJvzvYQj7kZCe+yzJOP/HIDznP3Ha/MJKHPgvrAjp5G3I/2fcSvVr3kDs8V6U+LfUKPh8HZLsmyPQ5YKF9P7g40b3beiq+Vw1qvXKkej/g0YA5zFthvyDl8j54Be8511+aPGCjO7we40U9IkuFPih0D7rbtEU9BN12P9+ChL2SOMOxytatsK12fz8hikk+asapPRol6r0fYHg/fuSDPvbEkj6Nzr+84CVsP4pTJr4CIUC+0JgUPVbRdz/Wiss+7JqEvD4EHL2KqWo/LAQevxRFpL6R0Km+UiEjP+6gN75xlDU/spXHvocsDz94f0U/YoTKPeafR70gayA/IwXvPekjP7u4aTe9q/19Pxm4Ib8bKZU+VzeaPk71Jj8WRwK+JnU3vxJ6sT4OeRc/EoEBP72hwz0SYWe9+/1aP54/wD2JW6C9aZ4WPdznfT83ATA/t/bmPjTRY70t+xA/f0VQPxe2Pr4PlMw+RCTCPgRqCb/Y20M+rewnvqgjTj8byg85z9x2vzCShz5x6wI6vSxyP2v8Er3e+5A76vGkPpdfCj5TRGO7Q+LyOX6mfT+1ktC9RW8qvk0var35pno/Kc+AOcpbYb8m5fI+9wLvOddfmjxgozu8HuNFPSJLhT4odA+627RFPQTddj/fgoS9kjjDscrWrbCtdn8/IYpJPmrGqT0aJeq9H2B4P37kgz72xJI+jc6/vOAlbD+KUya+AiFAvtCYFD1W0Xc/C+TZPvktE70B12a9RwdnPywEHr8URaS+kdCpvlIhIz/uoDe+cZQ1P7KVx76HLA8/eH9FP2KEyj3mn0e9IGsgPyMF7z3pIz+7uGk3vav9fT8ZuCG/GymVPlc3mj5O9SY/FkcCviZ1N78SerE+DnkXP5X/+z4vc8U96h1hvQAHXT8oT8E9LcDevW2ED70yLH0/NwEwP7f25j400WO9LfsQP39FUD8Xtj6+D5TMPkQkwj4Eagm/2NtDPq3sJ76oI04/G8oPOc/cdr8wkoc+cesCOr0scj9r/BK93vuQO+rxpD6XXwo+U0Rju0Pi8jl+pn0/tZLQvUVvKr5NL2q9+aZ6PynPgDnKW2G/JuXyPvcC7zlqapc8yGCTvFTkVj1EgYI+UNmNPCbxQj1VNHc/2YKEvS7UK7HvQDGxrXZ/P9EDUD6EN4Y9qrDZvZWdeD8ptII+xRSJPh7h0LzRv20/jEQkvr7WNb4+rBw9Z154P85Yzz4sKkK8MIxFvfG4aT8qBB6/FEWkvpDQqb5UISM/gKxIvjxrNT9+0Me+tNwNPxKgRj+a9dc9OqTIvCIcHz8jBe89uyM/u7VpN72r/X0/4RIhv9oVlz4PnJk+9kknPylHAr4ndTe/C3qxPg95Fz8ASgE/yr7DPZP+Zr2DHls/x8TBPbDfvb18Cic7Qb59P4LnMD+edOM+VFtgvStLET+wAFE/EtU7vovNyj7hj8E+Xk4JvxsLUT5gfi6+4Q5NPx7BDznP3Ha/LpKHPi7qAjoxXXA/oaYtvQ1Jqzv71K4+lzdHPhMI/TtYBsq6vBl7P1g/C74L6ha+HoApvYaTej+54ms5JpRmv59v3j50l/Q5RGCQPBHtdLx1Hmk9Oz+CPkhTJT2InCc9+CN3P9uChL3XmeGxCIQLsK12fz/6Uk0+yN8lPXnpvr2dcnk/mlWCPqKPbj4NpQi9pB9wP6bOIL78FCG+7/o4PfdTeT+ox8w+5RJDPE86Xb1mNGo/KQQevxNFpL6T0Km+VCEjPzsJbr7m2zQ/nTXIvj/LCj+o7EY/zpbIPdyvhrusKx8/IwXvPZsjP7vOaTe9q/19PxqyH7+wLZs+kEWYPk/6Jz8aRwK+J3U3vw16sT4PeRc/FVEAP2NBxD3aQWW9pbBbPx+RwD3paaS9dDsDPUfnfT+DTjI/yLvbPoG9WL3zlhI/WE5QP+nDPr71uMU+svbIPsrwBr+YmmA+gtE1vsszTT9c0Q85z9x2vyuShz5u6wI655ZwP5xCRL0ulsE7ZDStPrfeTT6WkA89ADLsuwubej+Nchi+J1QFvtObBL1lzno/WMI9ObHab7+c87I+qGj+OaMLgTzfr2S8ahZpPSPbhT60o0U9QprLPJi0dj/fgoS9IF4wMlJX97Gtdn8/3gVAPqLW9Tw0i6O9LoJ6P6rqgz6a1VQ+dadLvRs7cT9B6R6+a4QQvnPkaD2I4Xk/AJHTPhQhqTww8Iu9o2doPyoEHr8TRaS+kNCpvlQhIz/EzIi++w40P2BpyL76oAc/xKZGP9sPqT089Co6mBUgPx4F7z3cIz+7q2k3vav9fT8sbB6/oPCePuL7lj7zlyg/GUcCvid1N78NerE+D3kXP6hy9z5PmMY9NQ1dvRdPXj8xkcA98mmkvX87Az1H530/Z1YwP6xl2j4FbFe9W3MVP1HqTz832z++I/C/PkzQzz6+tAO/TEVlPl4FNb5vBE8/18YPOc/cdr8ukoc+hewCOjQtbz/Z0ye9gYqlO+RQtT75KmM+pTV9PY4VZ7y+F3k/AMcnvhERBr6Se8q8+Dl6PwxTFjlQ/nW/3L+NPoV1Ajowt5o8YQ2CvBvNSj1vx4k+3ydEPWkElTwuNXY/24KEvReegLKvwuExrXZ/P2rlMz6Ga/I87+CbvWImez+2mYU+guFPPudYZL3NLnE/D6IevtrUDL7MDns9cPR5P/f93j5oCQo8mXutvWZpZT8rBB6/FEWkvpDQqb5TISM/8Y+Nvp7MMz9ubsi+o70GP2NxRT8KaII9VCuYvMYPIj8nBe89EiQ/u9JpN72r/X0/PhYev6ztnz7XopY+rcAoPx1HAr4ndTe/EXqxPg15Fz/xr+g+mR/KPafdT71AQmI/1MTBPa/fvb1ICic7Qb59P+IcLz/5DNk+/hdWvUVgFz+o7U0/ZI9Hvro8wT46p9Q+oA//vtcDZT58Mzq+X1lRP7DCDznP3Ha/LpKHPpXrAjp/0Gs/Jd0rvfWFqTtbGMY+su+HPgj8iz3Espq80SR2P4MvOb7iGAy+jgfAvD9CeT8xnxI54n12v1A+ij5CtwI60ezePHFxIbyE6TM9UB2LPuLE3zxQ3KY8+jZ2P9uChL2cs7Ex4FwkMK12fz+YsjA+GYNNPU9hqb3j8Ho/1y2GPt+eZz6pGEi9TdhvP504IL7m3Bm+D9JhPUuBeT+Xx+g+PmCbvMDku709v2I/KwQevxFFpL6S0Km+UyEjPwfEgL7qczQ/FljIvpoWCT9LcUM/sdxTPVS7Wb22PyQ/JQXvPSokP7vXaTe9q/19P2L+Hr9GQZ0+V5GXPtpRKD8bRwK+J3U3vwx6sT4PeRc/RIzWPp8Wzj03qT+9ebJmPzdPwT0twN69doQPvTIsfT+sZDI/jvXUPusOUr2BABU/PlVKPxhBVb6YqMI+FabdPsNi+b6qOFo+r1k4vsbdUz8luA85z9x2vy2Shz6t7AI6jrtqP5AZHL0j+Zk7CV/LPnIcij6Ovk09qwtnvPIldj/AsjG+YD8avpHf9bzrB3k/3o8kOYj2c7/kJps+g2IBOqpVGj1v6nm8MRI/Pfvhij4RPsw7VPb5PNxFdj/ggoS94BKVrsyyj7Ctdn8/eG00PlJzlT1DaMa9GBN6P0Ichj44+4Q+56YTvYLEbT8pLCO+BR8uvk+NOT1/rng/ImvpPuW3Ir3lR6q9xJ9iPysEHr8TRaS+kNCpvlMhIz9GIlq+WzE1P/MEyL4Pdgw/QBBDP2/lgD1lOYy9RRIkPyMF7z0MJD+7vmk3vav9fT+KbCC/rASZPmv8mD7anSc/G0cCvid1N78PerE+DnkXP8vEwz70yNE9l+IuvcrVaj972L892rDzvYWOcL23mXw/3MM2P91Y0T7Hfk69l/IQP4JVSD9Ecl2+TXbGPsSF3z73Q/u+BA9RPj12NL4AGVQ/GMAPOc/cdr8tkoc+ouoCOiXvZz9sCiK9XNWfO1jD1z6cBaI+jNSdPPj70rvRyXI/nGhEvk0wJr7krBq9ZZl3P7RtPDmnHHC/ZZCxPmKr/jnkcj89QM1SvMb5Wz3PeYc+EI6xuIDNOT01mnY/4YKEvYFNVDANdJkwrXZ/PxaFQj6jx6c90Vblve3QeD9ItIQ+vf6QPnnLyrydTGw/9NwlvsupPb7OuRk9j/F3P5Ul4D72syy9bEGFvYhOZT8rBB6/EkWkvpbQqb5TISM/3VE8vpmKNT+Spse+hdEOPweaRD9CDrU9gDZxvSaxIT8jBe89DCQ/u7ZpN72r/X0/U4ohv7mxlT6jDJo+5gwnPyJHAr4ndTe/DnqxPg55Fz8/c7M+La3UPaxOIL1wEm4/Wn7APQvv672esUy9yNR8P/mDPT8tLMc+lXVEvczTCz9MskU/wJtnvqEVyD701OQ+Yf38vqnRUj55cDW+U2xTP5LIDznP3Ha/MJKHPvTqAjr3WGg/w0FHvd2KxDtPetU+KGKmPsrP0Lsv1w47eRlyP2+sS74Y8im+JiFVvQPndj+E0k050ehsv2ICwj46SPs5vV9CPXx7abxwFXE9KJODPivTnTv+h0U9XBd3P+CChL1A7zsvVLWcsa12fz/fCE4+clKfPYzN5L25VHg/ezqDPkD2jz6kO8a8sKpsP965Jb54PT2+0noWPTD6dz94+NM+RoDNvLSrTr1ZlWg/KwQevxJFpL6V0Km+UyEjP9lRPL6ZijU/kqbHvoXRDj/WLkY/ZejVPTfZFr1jjB8/JwXvPY0kP7vTaTe9q/19P1KKIb+7sZU+pQyaPuYMJz8iRwK+J3U3vw16sT4PeRc/F7ioPvpr1j2YuBa9lQZwP/bQwT2clc69+iaIvPKAfT8c0z8/oMjDPucdQb014Qk//xFGP1TXZb6WY8Y+p3XlPsEL/76w0Fc+ARc2vgt0Uj9Iyw85z9x2vy6Shz7J6wI6UlJpP6F3Wb1LgdY7r+XQPkVZqD4wOvG7plAnO+3BcT8HqFS+6IUyvuM8hL3C2nU/7JVQOWlhbL+xksQ+Orb6Oe7ZKT0QTpW8Ns5gPQMHgj7Iov08MHk6PZ00dz/bgoS92qvjsWx9xbCtdn8/UspPPnWzUj2NVMy9fQV5P/tdgj7fLoA+dlznvEYDbz9GeSK+4NArvlLyJz3323g/bLzMPuRTrDqhhkq9yExqPywEHr8QRaS+ktCpvlQhIz82Ilq+XDE1P/AEyL4Qdgw/89pGP7zV0j3iJFe8ngQfPyUF7z1SJD+7yGk3vav9fT+JbCC/rgSZPmj8mD7bnSc/IkcCvih1N78LerE+DnkXP+Jbpj4GytY90JwUve5vcD8dPME9aQevvXBgoTz13X0/MSM9P3QGxT5hV0K9ABsNP0bgRz+AKF++eXjGPti54D5IPv2+GG5lPrPHQb5HcVE/2MUPOc/cdr8tkoc+HuoCOjuNaT/1tH69xzz7O6sxzz6696k+6uxmPBjkoru8c3E/szdevgQ4Nb4J5Zy9gvl0PzZ/UDloYWy/upLEPne7+jnKvfs8ARJMvBGCSD3isIM+JTk7Pca5Bz3t9nY/24KEvfvq6rE/I6GxrXZ/P1aARz50wAk9Cg2wvej6eT8f8II+r35fPpvAKL3Y3XA/IZsfvkCNF76QKFA9k615P2lOzz4zxZc8tL14vRGDaT8rBB6/FUWkvpPQqb5TISM/C8SAvulzND8UWMi+mxYJP2zeRj/OZLo9qlhyOjyDHz8jBe899CM/u8BpN72r/X0/Yf4ev0NBnT5ZkZc+3FEoPyFHAr4ndTe/DXqxPg95Fz+FQa0+5LLVPRzGGr1lN28/rD/APYxboL1snhY93Od9Px2WNz+PUMs+d4tIva0VEj9a40k/6wZXvkRCwz5zUN4+k4/6vgyuaD5cokO+rupRPyW0DznP3Ha/LZKHPvXtAjpUu2s/uldqvX0m5zvAeMU+mCmSPs63PT0gf2K85Ah1P/S/Sb7ZSkK+HfuuvYVDdT+uXTc54/ZwvxTirD6olf85a22dPJBKh7zIWUY9hBiIPiDHSD2v6Zw8H2x2P9mChL3sqsGxdhQcsK12fz/b1zg+j4HqPGghnL0j7no/9+iEPhhCTz6CMWO93lBxP0yYHr7uqgy+Ocx5PZD3eT+E/9g+ZiaPPP7LnL1W/2Y/KgQevxNFpL6Q0Km+VCEjP+mPjb6czDM/cm7IvqS9Bj8hNUY/sOWVPZ0Aubua7CA/JwXvPSAkP7vCaTe9q/19Pz4WHr+q7Z8+2aKWPq3AKD8aRwK+KHU3vxB6sT4OeRc/I5W6Ptly0z3VrSa9g7JsPx08wT1sB6+9dmChPPbdfT9jjC8/gVrYPvtnVb3oHxc/MPFNP7aCR744QcE+c5jUPnB7/r7Ko2U+iQA8vsFhUT/0uQ85z9x2vyyShz4V6gI6fflrP6TGMb2yWq87cD/FPqQEiT7IU4s9v0mbvNH/dT+FjkC+TKpPvkulqL0rHHU/ZcAPOc/cdr8ukoc+HeYCOkyDZDziiUe8NG5RPam4ij5ZsCI9hpeYPCgrdj/dgoS9AFfer2TfgzCtdn8/Q1IxPv1HGj0CiaC9zyV7P/39hT7j2Fg+QQhavfurcD8bMh++3asRvvS9cT2By3k/U5PkPgqjmruBd7i98+djPysEHr8TRaS+kNCpvlMhIz/GzIi+/Q40P15pyL75oAc/0WtEP38iZD34nhO9WEwjPyMF7z3aIz+7smk3vav9fT8sbB6/ofCePuL7lj7zlyg/G0cCviZ1N78TerE+DnkXP8qayz6TStA9tOI1vdQpaT8O0cE9mpXOvQgniLzygH0/n8ssP1KH3z7Ye1y9daUXP7e5Tz/QtUC+3w/BPnZVzz7FfAK/461dPqScMb40fFA/A8wPOc/cdr8wkoc+0ecCOr1vbj/90QG9PQ2AO2qouT6KZFg+zteBPcA8Yby8qnk/uJAhvqMbUL4ItKO9s4h2Px43IjnTT3S/1vCYPt2OATrcu1c8n5JDvMmLWj3zJ4s+qnBzPNaRxTyxQXY/4YKEvRCCfjEu/FcxrXZ/P4u2MT7FX4E9Ph22vWyQej9DOoY+jgJ5PpkKML0X0m4/zpkhvl/aI75nIE49QR55P7Og6j7TswC9qBO3vbs9Yj8qBB6/FUWkvo/Qqb5UISM/OgluvufbND+dNci+PssKP4DoQj87TF09dNCEvUSPJD8nBe898iM/u8NpN72r/X0/GrIfv7Etmz6RRZg+TfonPxxHAr4ndTe/C3qxPg95Fz9t7d0+9oXMPdhARr388WQ/en7APQfv672BsUy9yNR8P68TLD8TGOc+K/JjvSmSFT8XY1E/cWQ6vv6Ywj6gi8g+XwAHv7noTD6XEiO+T2xPP8rJDznP3Ha/LpKHPsfqAjrCP3A/PV+wvBv4LTu2eLA+fmotPqvkHj1J69q72Bl8PyHGBb5Gck2+DDmXvcXVdz/ODUo5VKFtv21zvj6e//s51ReFPCCBf7yQh0w9yIeJPnSj4zqhvB092GR2P92ChL0le6AxrsJ7Ma12fz8uqTo+Z5yhPRbN173RcXk/+oeFPn8bjD58NvG8TOJsP2ayJL6DMje+CxInPRpDeD9mo+U+kZExvbGNmL2WvWM/LAQevxFFpL6O0Km+UyEjP3asSL4+azU/fNDHvrPcDT/GtEM/pGuaPbMNh72yBiM/IAXvPS4kP7unaTe9q/19P+ESIb/dFZc+EJyZPvVJJz8ZRwK+J3U3vw56sT4PeRc/HxnvPvyfyD2ul1W95ZRgP33Yvz3XsPO9iI5wvbeZfD+T2Cw/cWHqPhMwZ725XhM/BVdRP75/Or7EB8o+9zvBPlhDCb/mfEQ+elQjvtpuTj8FxQ85z9x2vy6Shz6f5gI6LOFvP3ZW5LwhOmE7pzyyPurMMj4abSE8kEzmuuMNfD+CBQC+EbE8vsNzg73oB3k/iaFwOd+CZb8dz+I+Q2nzOddfmjxgozu8HuNFPSJLhT4odA+627RFPQTddj/fgoS9kjjDscrWrbCtdn8/IYpJPmrGqT0aJeq9H2B4P37kgz72xJI+jc6/vOAlbD+KUya+AiFAvtCYFD1W0Xc/C+TZPvktE70B12a9RwdnPywEHr8URaS+kdCpvlIhIz/uoDe+cZQ1P7KVx76HLA8/eH9FP2KEyj3mn0e9IGsgPyMF7z3pIz+7uGk3vav9fT8ZuCG/GymVPlc3mj5O9SY/FkcCviZ1N78SerE+DnkXP5X/+z4vc8U96h1hvQAHXT8oT8E9LcDevW2ED70yLH0/NwEwP7f25j400WO9LfsQP39FUD8Xtj6+D5TMPkQkwj4Eagm/2NtDPq3sJ76oI04/G8oPOc/cdr8wkoc+cesCOr0scj9r/BK93vuQO+rxpD6XXwo+U0Rju0Pi8jl+pn0/tZLQvUVvKr5NL2q9+aZ6PynPgDnKW2G/JuXyPvcC7znXX5o8YKM7vB7jRT0iS4U+KHQPutu0RT0E3XY/34KEvZI4w7HK1q2wrXZ/PyGKST5qxqk9GiXqvR9geD9+5IM+9sSSPo3Ov7zgJWw/ilMmvgIhQL7QmBQ9VtF3P9aKyz7smoS8PgQcvYqpaj8sBB6/FEWkvpHQqb5SISM/7qA3vnGUNT+ylce+hywPP3h/RT9ihMo95p9HvSBrID8jBe896SM/u7hpN72r/X0/GbghvxsplT5XN5o+TvUmPxZHAr4mdTe/EnqxPg55Fz8SgQE/vaHDPRJhZ737/Vo/nj/APYlboL1pnhY93Od9PzcBMD+39uY+NNFjvS37ED9/RVA/F7Y+vg+UzD5EJMI+BGoJv9jbQz6t7Ce+qCNOPxvKDznP3Ha/MJKHPnHrAjq9LHI/a/wSvd77kDvq8aQ+l18KPlNEY7tD4vI5fqZ9P7WS0L1Fbyq+TS9qvfmmej8pz4A5ylthvybl8j73Au85sOSaPDhxkrw02oI9IrxiPpiuCL0YwTo97jl5P9iChL2gqJQuBo4NMq12fz9Ralw+5GioPbhH0b3fu3c/ZwVwPkf2kT77YaS8Dd9tPxM8DL5+Uym+lEfiuaMHej/L/a4+leZxvHaCLr19TnA/LAQevxNFpL6S0Km+UiEjPzElGL7mjzU/gs3IvsUQET/u2UI/DxSzPeIcMb2CJiQ/Te/bPQzJxbvH1Os5zIN+P3tVIL9rZZg+1B2aPueVJz9BIpe9O6o1v9TjwD7wPhc/gUsEP7udAz4dnJ29AMlXP+4h3z3C/z69vdsMvLYvfj8nGjc/kiXdPlYiWr1//Qs/5RhXP8EmI75XALM+6OjDPgtfDr8TQCM+esYCvoo7Tj/8xQ850Nx2vyuShz6h5wI6xjV1Pw2q0rx2y087pXqSPlGsGT6+VDC7HPHPOZIZfT/0IQi9XdskvrFHL72SR3w/vwlkOYBWaL89/dY+Mmv2Oa3JpTzzz4288F2APRqBiD6qgLG9CwtEPbttdT/egoS9RdaaMhfC7TGtdn8/unZMPhglnD03xsi9atJ4P31Gaz78O5M+8nqLvLL8bT9p2Qe+XNkzvpoCBjyGtnk/o5NbPu540jxlDca90Lp4PysEHr8URaS+kNCpvlMhIz9eKfC9ZLUwP7xW8r6Z2Ag//qIkP0VzbT3yoJa8HmtDP3dzOD4B0W490EBHPoFidj/Nsh+/Q/CZPisymj5M0ic/aoVpPVC/L7+aLNc+uTIXP0ZDCj8pnUg+JfP9vUgdTz8AXNI9a7ALvdT2HTz8e34/lQEsP3IZ6D4G8GS9wEEVP+1GXT9Jywq+QCSuPl59sD4Oegm/h6bQPfPWob2nalU/msQPOc/cdr8tkoc+Q+gCOlHYbT9rqxy8XIiaOqhPvT4tX10+/CG4us/QmDkw8nk/O8+nPWamGL5OFKK81Td8PzdoLzlqRnK/02SlPo97ADoB3Mk8l7qRvHfhfT22Z9A+q4TivaZMkj0HZGc/34KEve5doTOocRszrXZ/P6uNSj5a+og9L7DgvcvGeD9BcII+i3aYPhCU/bzRY2s/OgskvousTL7izjQ9YTN3P1lwgD2y/jM9ne+7vTkqfj8rBB6/FkWkvpPQqb5SISM/JG67vYTiJD8XjRq/YurrPiKjtT7/HUm7+VYyPOFUbz/AVIM+1VwuPo64uj4r9mA/eokhv6PylT5nB5s+HMUmP9n8aj4PyCS/LIrbPvpEFz/DJBE/35OIPiZuPL6Q30E/bB63PXBT8Lz4vkQ9MpF+P17CBz9B2/k+83N2vd/OMD9kxmY/t6O+vTFosT6d9Xc+wgPmvq5DXT32lQ47DEtkP5fVDznP3Ha/LpKHPrfrAjozYlA/CDMCvBlrgDoXsBQ/XOq8PiZaE7vMQWc6hO9tPzRywD0SThG+QKqYuthDfD+ezA85z9x2vy6Shz4K6wI6h1ebPDVtn7349Ak+lQgMPxubr71Hxs496JpTP9+ChL22eo8y5uVdMq12fz9tPGc+vz2HPSYvtb3tx3c/4XaCPg/FqD6qP7i81KZoP/JAKb4z4Wi+WU4CPSKKdT9KtuC8BnswvbIqu7tjqX8/D5Ygvwbao75l4rC+NsoeP3Ieib3GLRs/fK4tv2i60T5M7AQ+SIV2vVSDCTxcW30/OY4xPrN0Lj7O/JM+dgptP+kIIb/RF5g+Yz6dPjNAJj/1J8Q+0dwXv4iGxz5mVRc/jtgXP+/ioT5VyXa+1zgzPzuLxz2iX/a8SptDPTtffj/E6eE+m0GuPuLhK70UTFQ/GVdtP2GRlb33g4U+OqiEPslkqr7g63Y7gUWWPWqscD8PyA85z9x2vyyShz7p6QI6kaIYPzoynrzkChw7t3VNP5OoMT/FUae8h0+0PJcoOD8olBi+7gLzvU7ZlzytRHs/tckPOc/cdr8ukoc+fOsCOqk0HTxA9he+xceQPmE0Jj8VFFu9Eu/2PX3CPz/ggoS9mHWfMkRVlzKtdn8/7AaIPn0KiT3QlVm9KtR1P1gnfz77wbc+PNzlupZFZj9lfiq+cSuCvitJsztF43M/myytvdZrGb6UoJE9c4Z7P7uvJL8+laK+dA69vto6Fz/Z/ZK9pU8gP0cIJL/vbeA+kNm3PfTjCb04DEo7ydF+PxG8Cz61R44+t1wkPgbubz9g1x+/YAydPgZcoj5RBCU/H1bwPga9Dr/r27I+cL4WPy5DHj9GH60+5jiPvu3vJj/7ne09Tk4CvXgyQT2H2n0/cVAYPy7JyD34DEa8uTJMP/FEej8IozS8O7BePaPUTz7xEQ+/FU6APcaEFD6+ZlA/mMQPOc/cdr8tkoc+NukCOq9UDD8VpIC8YMb9OnUSVj/UzGQ/UcIxvaBRtz1C8t8+N9cKv1lLTL144bs7ALJWP97VDznP3Ha/LZKHPuTrAjrJVOM77tERvryd9j5YbDc/cGHHvLbZ+j3Csi8/4IKEvUrHKrMEdqwyrXZ/P+DXiT5Il3Q9504OvaHpdT+SM2g+foC0Pm6KRjw/Z2g/kAsXvgdPgb6a4QO8FMx0Pxuq271T/0u+yO7XPXTldz/s5ia/jIShvvovxL7OvxI/trjIvXOIKj/XcQy/Dcb9PonSqz0eAKM8GKDbutULfz/gZw8+b+zDPgjl0T0uTmg/djkev2B3oz4y/Kg+bVgjP5Fo5j7T8hC//fS3PvT5Fj92nyQ/NNmrPqBmlb6dmR8/tZoPPiXIC73wgT49IQp9PzgvTz8asOw6q3JpuRZeFj9nq28/+xOQvJvNQT3CErI+EKYyvy66pj0eVRo9Yeo1P6fSDznP3Ha/LpKHPgjsAjqXdVc/XrCBvZvY/ztQSAk/kEphP4pYB73lg309/XnwPvudXb+jBWM9e7MGvFev/j4e1w850Nx2vyuShz7b6wI6XtEgPIYCib0A7y0/i+1EPzN5f7w/VMM9YLAhP9uChL2EIeQymo71sa12fz8VSFs+XFGAPeeIJb36VHk/nalKPjOmpD4Nz6g8Nf1sP00v5726wmi+hGwhvP2adz9Djuu9O1NKvk91oz2EYXg/vK8kvzyVor50Dr2+2joXPzGaCL5bCjE/TkHwvspdCD+iUhY+zV5kPTgKfrtx0nw/NxknPjOPtj69W0g9+SlrPxCLHL9N0ak+v4qvPoKbIT/SL5U+jAgfv5yv3j5WRhU/eeMpP3uqpD7X0JC+qAIdP7hLKD4SehW9FHM8PSwSfD9oYkw/KSsYvWEYlju92hk/ruRRP4Yp67z0fCg97f8RPxnYGL8V0I49zc2/u/aUTD9EyA85z9x2vy+Shz4e6gI6AE16P9AFW73hCdg7GKpPPhdtJz9QKZK8tkGHPI2PQT+zdk6/jKiLPUNg9zt1VRY/h8APOc/cdr8rkoc+OukCOv7QdzwWMXM85llNPxYiTj9LScC8HI9qPSj6Fj/dgoS9zwyksme7+bGtdn8/fOYTPhgdnD3TSmq9WiN8P4eFND59vJU+ePLGPAuIcD9/56a96RhNvqoDwrtS8Hk/5vn3vX3jQr6/xzw9ax95Pw+WIL8F2qO+ZeKwvjbKHj+4bCi+c3g0PzBa075pgw0/g7DiPlD0tj2Lzl28VV9kP1UmID7FWxs+agJLuwHZeT+gNhu/zqGuPh+DtD6aOyA/HznTPch8KL9Q+/8+dqoNP/9cLj8EJpk+Iq+Evp2yHT95HTs+qwAdvUU8Oz3dOXs/PupCP4RSQr3srL87NIMlP8GfGD8OScO87NGbPEhhTT8/5xq/gdBaPdrBkDxtTks/RL8POdDcdr8rkoc+ZuoCOrSSf7/SgSM93EehuyOgKT3x3/Y+zroivOqQszuNQWA/sfTrvuQoJj3+WDC8pfBiPy3IDznP3Ha/K5KHPsjoAjrkX5o8zrNnPS8iVD/kpFE/GrUAvVkXFj0hZhI/4YKEvb4BA7IA3yWyrXZ/P7rc2T1GWK49OeeLvVUCfT8Pcis+E6uOPiAjzTzHAnI/EuaIvSsWP74l2hy7but6P0i2/r1L7zy+pp3lPKB6eT8qBB6/E0WkvpHQqb5UISM/7KA3vnCUNT+ulce+iiwPP8JiIz+mzdk9mujtvN0MQz8lBe89DCQ/u9BpN72r/X0/F6Eav1axsD60o7Y+B6EfP9O3KTvw5Sq/HsIFP3bJBz9PmzA//gyRPqrPdr5U/h4/WzJDPuhFIL3M0To9pdV6P9JyYj9v10q9GBTIO4Bv7T7iGC07OSqgum6f1ba5/38/iRb6vuJKvjxedD89q/teP4O7DznP3Ha/LZKHPkLsAjqeunu/KoEsPa0nqrt2ITU+XF3WPlwaGryqwY07kHdoPzqS176fBrY8wZw2vKkdaD8M2A85z9x2vy2Shz5T7AI65F+aPM6zZz0vIlQ/5KRRPxq1AL1ZFxY9IWYSP+GChL2+AQOyAN8lsq12fz8Lk7U9iygRPaL/fL3hVn4/giMiPn7VBj75j/Q8b2V6P4seVb0pYbK9KsLmuzKsfj8BMeK9xliyvSUi7TvUcn0/KwQevxNFpL6R0Km+UyEjPxsdc75dpzU/9d2+vnB8DD/vzh0/AJeVPUffa73xKUg/adhWPlAwgjyAyzu9Wv55PxehGr9WsbA+taO2PgehHz/FuCk77+Uqvx/CBT92yQc/T5swP/sMkT6qz3a+VP4eP1cyQz7vRSC9rdE6PaXVej+zMVs/pSdKvcRmxzunogM/oG6mPrp0NLw1d3c7NBRyP/rD675UHVU9bXDDPEvFYj9NxA85z9x2vyyShz4S6wI6nrp7vyqBLD2tJ6q7diE1Plxd1j5cGhq8qsGNO5B3aD86kte+nwa2PMGcNrypHWg/DNgPOc/cdr8tkoc+U+wCOkrE6zycpus9kBJcP4ydTj8+ZB6919nQPPCuFj/YgoS9OIuAsji10TGtdn8/NA0nPnYgBD3JtJa9Sbt7PzsJAz4x2+A9b0r9POo1fD8wvDe9PLiQvdLaB7zHF38/HfUSvlz2gb0t5q+6EdR8P7R2Gr9qRbG+kDy3vjR1Hz+x+QK+FOYxPzGX6b4OeQo/BdIoP/KClD1cBIS9QdY+P3qRmT2zMa08050UPsiAfD9Xcxu/zVGtPgo6tT5UKCA/5/h3PUlKKL+yPQc/lbAIP/l3LT8qh5k+sYCBvuQ+Hz/imUM+PDP7vGy5AT1eCHs/j/1dP2sfK73Eyqg7ZRb+PokTxj7JKry8V4giPM76az823vO+Vx1oPc5DSDwim2A/Q9UPOc/cdr8tkoc+sesCOlL/Xz/KaVu97WzYO9tV9j5PKlc/qtDyvITYRT178gk//0HmvsC02LzB6TO9J0ZkPxEt2TjL1Hq/ObtMPt8DBToW6DQ9J0QOPmyraj+An0k/+hZIvYuP6rttPR0/2oKEvZ7hCzNHlacyrXZ/P9+tmD56h+c8CsXIve/zcj+jTps9oC6JPeo/Az3ZjX4/GroAvYF+HL2c+wm8ba1/Pz7kVL5IWku8phc1vMNeej+lzRK/VqLJvvNi0L5Uihc/SonxPTncJD90AAm/DqkIPxKsED/6Z6U8VMWKvOwXUz8rMDW8SCOiPSKzwz7CrGs/Gl8dvzBbpT431bE+T1UhP6AcMT5v6yG/l4MHPxHRCT86YSY/Sm+qPjo1i756dSA/Zu1EPjirabw9cpM7OjF7Py9JYT8M40q8jh7IOrIU8z7Atfk+Itc0vbPHzjz3G18/5V3vvs25eD3ekg+8NsFhP2nKDznP3Ha/LJKHPqfqAjqxWwY/itDBvEEsPzuP0lk/i9pVP8UnIr2fCH09Z3YLP7tObL4I1kC9a5OCvTJDeD+otxs4jFd/vxm+kj2Qawc6RRBQPXjaGj6dDHc/wHZHP4W7R72HkHO9pEEfP9mChL2gq4ixQlnxMa12fz8o4dI+BP/hPEvQ/L3wBGc/qewYPYI1zTxcMOo866J/P4hZn7yw2Mi7yGmJu8vxfz8h5om+wIc8PcOQHrzsPnY/i5UKv5ax375BKOe+5wsPP9QosT6fdRc/snHuvpVNDz+YEcA+DQlbvaigsTwe2Gw/3LGEvLSmCz6pOvQ+5TteP80AIL/0Q5o+WPisPmjOIj92Co8+lygav3LEBD/l8Qk/plAdP9v1uz4QFpC+BpojPzvcRj7YSK86XYGwvMMQez+5WF4/jixNPQdhyrvIb/w+HV0gP98ac71SQkQ9JpdGP0Ar477sQIE9+Hj3vNG4ZD9v1A85z9x2vy6Shz7Y7QI66UzEPh5bLTv4+qq5qm9sP3heYD9Y1iW9Bk2ZPbqm8j68Dei+QXWnvBk62b3dg2I//Zzit+imf7/TflW9CJQHOvfaJD0+zS8+ljt5PzMNTz8IFOq8VLrtvW9oEz/cgoS9mU9yMsm5QDKtdn8/ABrhPvtH3Ty3RQm+H0BjP3GwBz2nKx08T9GPPOnOfz8iwZ28MfiyOzqlsjvl8X8/eq2Uvt3/sD0NblS6tPdzP04QCL+6zOW+s3Xtvh1xDD8al7M+VZUdP72xrr7nJR4/sODcPg+Ekb3rfgk9OxNmP43HjL1RDkY+x0nsPujxXD8n+yK/Io2NPpIspz5RPyQ/2R6YPh1oGL/N3wQ/5FsJP0ktFT/1DME+u+SEvqjmKz8S90E+EabAO/9r6bxOQXs/a7tKP0eKFD5OhJK8dsYXP89vSD/lZ1O9UU2FPVPTHT+HpdO+Xa+XPdK8Q71aAmg/8cYPOc/cdr8tkoc+O+gCOtbnij5h6iM8bK6huppidj9vWGc/Y+y1vNBWVz2+Rdk+Kgkbv0HpKz2HfOW9KWZJP3dZ/bcpkH+/Ci9vvUuKBzoFAbA8krc6PopMej9WJlo/IhMePClRKL5uUv4+34KEvbw7HzOICoixrXZ/P+ku2T63eaI8MwjpvRLvZT89xHw9B+MYPHz5Qjvyf38/giQkvdccXztPo3Q8qsN/P+XBm75Ag+Q92RtNO8Yvcj+/4wi/PdTjvv1s676hSw0/xqw2PvOKLj/bJIW+NvooP7MWKj/p3ji9ZHchPeS1Pj82qEm+tAhyPiYT3j68zVg/lsslv+9FgT4vX6E+d2glP8dkQD6QYiC/LfMIP43oCD/VcA8/ydasPjweSr6X6zo/WJ8bPrcimTtdI7a8pPV8P6+RLz8+am4+6yrrvKNdMD81QWM/0dXbvLOwTT2/6ek++X7EvozPyD0ib3K9PZJqP3jMDznP3Ha/L5KHPsnpAjqFP4o+axoZvV0ElztvTXY/KOhaPwoIGj0HpXe9hncDP2BBAr9kh749h7+NvXBgWj+SgX84LTh+vwYg8T320QY666M+O7aZOD6Fx34/JXFjP1GUVD010E++DhnRPtmChL2gA4gwIOZuMK12fz9stMg+Ha80PFxBkr2HyGo/6sHiPfYlWjwdOnC8HmB+P/+WmL2uO1a7pBm8PCs4fz9OWaK+mi4CPsAWizobmXA/jZUKv5mx375AKOe+5gsPPyLWhz0HqzQ/Jl+JvgAAJz8AKzM/WQ6ZvGMSljyuujY/93dJvgyEYT4/KOs+ZndWP1oZKL/BC24+1V6cPoo0Jj/++eQ7Z6Irv4r4Aj/MjQk/e7gIP+PlhD6e7e69y81LP9Wjuj3fJX86kGYxvGbrfj+k5Rg/FkSSPhVGEL3BpT8/ohhwPyJBNDtzlvS7OpqxPiUyu764fwE+tqhPvZO1az8Rvw85z9x2vyuShz6M7wI6lamgPv/rbr3Lqus7iJpyPy/dWj8vyJ49TRsJvlaA/T4iqxS/DisAPkTBeL2DV00/FdYPOc/cdr8qkoc+z+wCOqwZ27sFUjc+2DuCPxehaT/gv5Y9wT5ovo0Gqj7agoS9LgVWslYiJbOtdn8/JPWvPjdODTxJyRy9jzJwP3BeIT7C+K48Wdn8vF+efD+34dO93Ug9vFhr9Txafn4/GWWYvuNkBT6nJ6a7khtyP9EGDb+IgNm+IcTgvgmSET+Z56Y9SewwP19Wvr6tSx0/w+MLP39NibzhyiQ8KVdWP5e/1b2bgg4++uzqPhUPXz/dVim/YediPoeVmT7AkSY/iNn1vVIvMr99EOc+BJ8LP22N/T4kBUc+LUZ2vXQ4WD/wrzo9gEXDu60ODzuTun8/W9MJP6FGlz4ZNxW9YNJJP0Qrcz9svbM8vMOMvUK9mz7LkLS+HAQRPp7PzbyAtGw/kMsPOc/cdr8ukoc+1+oCOkQd0j6RVfW8A/5xO4ZSaT+UrlY//l/KPdZHJr5ssAI/JuI1v5jq6j13bl+9QTExP8rSDznP3Ha/LZKHPtLqAjrOW9e79Nk+PuWuhD/OV20/ZaOOPYVma751SJM+2IKEvYzWgTO23hezrXZ/P/ablD4G1Sk8yMQPvc3MdD+6lD4+5AUCPaING72DNXs/ZpLtvQCWmLx5fw89nBF+PwZibb56tfo9bkM+vFQHdz/D1A+/GgfSvgYN2b74dxQ/EKcTPsCNKD8kZ+6+JtASP9MGwj7uz/K8SxJGPJ/DbD+iYd66iaO8PZuxxz4Ai2o/3lYpv2DnYj6JlZk+v5EmP6yDFr5qRDO/p4XePvUDDD9PF+c+IsU6PqJ8K71vXF8/8nIZPfxqYLwyPWI8l8V/P8Y68T7zr5A+brcOvYa3VT8MmnI/3BvNPAq6nb0SH54+8SesvhHnDD7svoi8EXhuP/e7DznP3Ha/LZKHPkLqAjrM0AU/s86/PCY0PbtyKFo/fHxMP19bxj2wBwq+OgoUPy7pRr/njZY9DXN6vZ9IHz8K0Q85z9x2vy2Shz4f6wI6vqpru/F3RD5XmIc/D+FuP5B6cj2uxVW+mMqSPtuChL2lOZAzZCCrMK12fz+5P3k+P389PNNsNr1iBXg/j85QPn5jJj3qyhy9qTZ6P9YX970gv8G8etQaPZnffT91dgq+CBzWPZP4gLxkM3w/PcoSv0Wsyb4wbdC+zoYXP7pFKD5LvyM/e6QDv10VDD/Opq4+63HxvLlULzzxgnA/60t6PTqXET5MTpI+CxtyP1oZKL/BC24+1l6cPok0Jj8r3Aq+RYoyv9aT5D6sQQs/QBzSPhIWTD5RECa9I5JjP1gJUT3EXaq8klu+PLCKfz9kyso+3jWHPlxeBb1X+mA/bR5uPyF3MDzFc+C8dmO7PlvPub612AI+yS/tvF0tbD8vyg85z9x2vy6Shz555wI6Z/EnP02LiT2bqwe8QG9AP/bpOD/vdZk9+FiivarSLj+Tlky/yDIlPZ+7lL3MZxg/W7sPOc/cdr8skoc+0ukCOsowRboMNkA+MkeKP9zfbT+mFkY9UOopvq1Cpz7cgoS92q0zsZYqlbGtdn8/CLpVPqoQRTxPGWa99O15P9WcXD7B0Uk98fwNvRaDeT/sy/q94TPqvEzfGz3ox30/uzY1vQYKoD3cdjy84PJ+Pz+0Fb8J6sC+mmLHvtKJGj8wuRc+ILogP8eaD7+H0gQ/VqOrPhQiqLwJgO87Ux9xP1hX0D1p828+CewtPi2ocz+WyyW/80WBPjFfoT53aCU/uUPovRYvMb8IoO4+CRIKP0GAwT4AkWo+HxA6vYRZZT8BTJs9xzXavP44+TyQDX8//87TPi1xej7EB/e8/F1gP7lyXT9uAeq8cis/PcRY/z7Wy+6+iir5PZbXEb0bHWA/W8YPOdDcdr8skoc+V+oCOqO9TT/tF5I9jxoQvOc4Fz8L5hM/Ohc5PSrpCb25dFA/UqpJv8lfFT2yXZu9wTYcP1XKDznP3Ha/K5KHPtvpAjo75DE7BfsvPjp8iz+dNGo/iYYLPdxd570us8U+4IKEvdamLDNDmoQyrXZ/P9xYPD4+wVs8nTmLvZ8Bez+3MmQ+aY16PTIt67xL9ng/tS38vY4wE71OUhU9srZ9PzrM6TsYKz89+jOXOt+2fz/NYBi/flm4vi+Lvr5fTR0/NmzsPdKCHj9iHxq//0L7Pn56pj4O1ja89tt8OwgScj+LiAs+U32iPuPBgD34tG8/JfsivyCNjT6TLKc+Uz8kPw18rr17hS+/KP/4PsLwCD/k5bU+kVaHPlMBXL3LHmU/xRPYPeNLAL3E0hM97kZ+PzyJBT/1Gjo+CZK3vJNSVT/Oejw/XWd1vafShT22vis/LPQUv8EN4z1Lqce8bipOP5TIDznP3Ha/LJKHPlXqAjpf4nA/fgcyPQmbr7t/36s+PQiYPi1PljwSoe27wmZ0P5hGO7/bI0I9WgaMvQo8LT+T0g85z9x2vy2Shz4s6wI6tYjuO+BQET4Ywoc/x8pjP0MRezwf62u9JaPnPtGChL3MdKGyBCmyMa12fz9WvyQ+oZmRPAWhm72933s/C+1gPu3DpD0s35W8atp4Pz1o7b0BK0i9vpn6PG7YfT+CwRA7TrwFPApsijxN9H8/ga8av9V+sL6Pb7a+768fP/UoDj0ClSA/ZQYev6558j7/GrE+Zw/4O/zmNrsPMHA/a7E1PtIzsz6Iayg7H3drP8wAIL/1Q5o+WvisPmfOIj8A/V69mMktv7nhAD84Hwg/MHKwPr+umT7pMoW9nxdjP96ICz654Q69c4slPV8+fT9DDig/Fi65PVyoNrx9sz8/FAYPP8kngL1MVC09QHBTP+UOJr9xqLM95UldvGyBQT/ZwQ850Nx2vyqShz6+6gI6im19P9p9+rtvFXc63JMQPq4oVD6b1o473pN0uk5xej+U4yO//IMsPczvjb1xkEM/8L8POc/cdr8tkoc+2ugCOqIOTTxTtNQ99DZ4P5HoWz+Um727h2gnvBcGAz/kgoS94Pi9sUDW7a6tdn8/nn4EPgpB0TyW3Za95w99PxlMST6XJ9c9ItcnOlSPeT/9g7q96IeIvaA8hjxlVH4/dH8nvZeBFL1bzqw8dI9/PwtsHL+CQ6q+pACwvnB7IT8u5O694GsrPwE2Cr/iN/4+NcXwPpfEST1b5d681ndhP9LeYD4m3oM+1OiMvLTZcD8aXx2/L1ulPjTVsT5RVSE/YVnZvHRWLL9AtAM/qc4HPwjk5T4a0qI+rlzyvcCbUz/YByc+Dm0YvYdHMT34JXw/QxVDP+/SaDznpuW657klPxHPzT4TXiq9TdmZPKIdaj/abBu/gTJ0PSgKUbyS0Uo/ksoPOc/cdr8tkoc+WOsCOpecfz/f0Ca9LYukOyVdFj1HjLk+0nG6u0HrFjvBl24/JxUgvx8H0DwFvnW9jBNHPxTJDznP3Ha/LJKHPvfqAjoqHIo8qreSPTdTYD/Z8VQ/tki/vJrRuzym2A0/3IKEvc71UTLaUxmxrXZ/P95f0D2bbAQ9PlOIvUX3fT9+iC8+WJz9PTvuojyeKHo/i5uFvXO1pb2cZo46BJ1+Pz6asb310JK9elJlPGRZfj/bjx2/oAGmvoSbq74VqSI/5eNYvnsQMz/Y79u+IcoHP8stEz/scZE98L5OvWpFUD/ecmY+ffPWPZaNEb2T0Hc/VnMbv8tRrT4JOrU+ViggP7CiyLv1USu/4TwFP27CBz/FzRs/2HGbPhxuSr4FuDQ/R886PgsmHr05STg99j57P16oVD8clgO9KMuBOxVIDj+voqg+5p+lvJBH6TtMp3E/YLgDv6bzQj14NNc78SpbP9PRDznP3Ha/LZKHPmLrAjrEcn6/U6BAPX4AvruIKcs9JObUPvAuH7yvV5E7dM1oP6YlEL/VOrg8GogLvT9NUz/Vyw85z9x2vy+Shz7g7QI65F+aPM6zZz0vIlQ/5KRRPxq1AL1ZFxY9IWYSP+GChL2+AQOyAN8lsq12fz8Lk7U9iygRPaL/fL3hVn4/giMiPn7VBj75j/Q8b2V6P4seVb0pYbK9KsLmuzKsfj8BMeK9xliyvSUi7TvUcn0/KwQevxNFpL6R0Km+UyEjPxsdc75dpzU/9d2+vnB8DD/vzh0/AJeVPUffa73xKUg/adhWPlAwgjyAyzu9Wv55PxehGr9WsbA+taO2PgehHz/FuCk77+Uqvx/CBT92yQc/T5swP/sMkT6qz3a+VP4eP1cyQz7vRSC9rdE6PaXVej+zMVs/pSdKvcRmxzunogM/oG6mPrp0NLw1d3c7NBRyP/rD675UHVU9bXDDPEvFYj9NxA85z9x2vyyShz4S6wI6nrp7vyqBLD2tJ6q7diE1Plxd1j5cGhq8qsGNO5B3aD86kte+nwa2PMGcNrypHWg/DNgPOc/cdr8tkoc+U+wCOsM5rjv7I7E9Xo5gP7aEQT8Y1LS9Tx+avSPwJD/bgoS9udJ5sVSKwDCtdn8/7fJ7PN0cAjlLSII5QPh/PxsavT0M3qM5tvCGOQfofj+DYJc8yUx4uWsifrnP9H8/qeKKunuixD1e4zG79NB+Pwh5Gb8YNr++MNXJvjWGFj/C7ZO+AZQsPxta/L4zru8+ZEqLPqaNJT2dZTu8Chx2P5/GGD6lzdU7nvSivPsTfT+ntyK/kPiePkLAqD6BESA/sqKWvko/Lr+pS/A+BXz1PswJvD7BYB2+I5p8PUNOaj8qBe899iU/O8lpNz2r/X0/TcJ2P2gT4j3u/l680rd3PlBKPT4sleW9XNStPBHjeT/NnP2+AU+3PIoRvT3LDV0/BtgPOc/cdr8skoc+gesCOlxGfj8LZ+q9kDVnPJBXPTx6yeo9lYG3PjvnNb006Ww/w+QTv+NxS7305Se+tk1MP8u4DznP3Ha/LZKHPiTrAjqHz7o7FvCwPV6OYD/EE0E/19fQvd7/sb3ejyQ/3YKEvfgVrTA4Qv4vrXZ/PxNNezzn7w+7g2h1Ohv4fz90Bb09kLzdu+CyRzq/5n4/6K2XPPYDkTsmj4m6FvR/P/P/FL0ivhk+BAJWvJvnfD8IeRm/Gza/vjTVyb41hhY/GkWsvgfpMD8m4M6+KO79PsDj/D7vU1U9K7HyvGIQXj9sXWY9bvtzvfhYhL1Fmn4/qLciv5H4nj5DwKg+gREgP1Fxkr5VBy+/f/DsPtII+T5eK7w+sW8ZvpNGdj0TeGo/KAXvPV4mPzvEaTc9q/19P1vedj+X+PQ9QqJxvEVUcT4GqT0+9J8Rvjnw3Txq03g/a+/9vuBPDD3Ca8g9erRcP17XDznP3Ha/LJKHPkLsAjowDX4/iiv3vZ3Nczy/Jp88wUP7PYn0tj55PUK9DLdsPy7BE78e7oi91+MuviK3Sz/Gwg85z9x2vy2Shz496gI6q4HUO8ZtsD1ejmA/wPU/P+1dBb4kV+O9GJwjP92ChL0RT/kxQpQwsa12fz8D2Xk8F9T2u67OJDtQ9n8/KNa8PcrKvLybg/s6ONd+P9GGlzwVjoo85+Zeuwnrfz/4OYi9LBd7Pl7P9rzGenc/CHkZvxk2v74x1cm+NYYWP6SKnb6WADU/d8CwvrD2CD+hxjk/gjHJvMZ44jw64S8/K3qIvUN8k755JOW9HN9yP6i3Ir+N+J4+QcCoPoERID+TH4m+gqQwv3xv5T5oWAA/SnC8Ppb+EL7QuWg9+c1qPywF7z13Jj87yGk3Pav9fT/NInc/KaINPkG0i7yQ0GE+K9M8PiL6U77Y1iI9U8F1Pzz7/b7aY3s9dVziPdLpWz/A1w85z9x2vyyShz7p6wI6lI19P7eBB74qqYU8+bEQPQO+DD7j8bU+K8ZYvTRNbD/eFxO/Q9fRvUXbPL7rcEo/mcEPOc/cdr8skoc+reoCOhHx6zsF2a89XI5gP2+rPj+6RCC+RZkIvpCCIj/dgoS9OLeAL1N7fzGtdn8/TDF4PJaxYrybXo87lPF/P0CevD3FIC29bA9XO0uufj+EP4s8CJqMPR9Kh7zsUn8/dEKIvVZtjz4vCxq9XPh0Pwd5Gb8WNr++MNXJvjaGFj93b629VjM2P05pvL57oxc/UUg2P7eFQb6ASlY+p50kP5UE/71MZhK/s42QvUDJTj+ntyK/jviePkHAqD6CESA/X8R9vpw4Mr+HLN0+5VsEP3ixvD41hQi+0x9bPTMfaz8lBe89ESc/O8dpNz2r/X0/6mx3PxM7Hz7ND528hCZQPvXrOT53IYy+fspXPQBscT/98Py+Pcm+PRP+/z2w+Fo/3NoPOc/cdr8tkoc+OuwCOjINfT87OhG+wz+PPKwUTD1D+Bg+NiW1Pp71ar136Ws/yRISv0jmCr6aUEm+ayVJP4XGDznP3Ha/LJKHPvnpAjqq1fI7IqevPV6OYD+PPD4/R00ovhlyD74SJCI/24KEvdCvfrIcWOQwrXZ/P+TrdjxZupq8ayXAO73rfz9Gcrw9dy1svUo8jzvYe34/hbSGPApgGj4KSRu9Wtp8PyFFh70Uo4A++1IDvRgTdz8JeRm/Fza/vjHVyb41hhY/vLVGPtGcKz/8nqu+xQciPzWN9z7rlsK+mTZ5PmMCQD8qgzy9HoMvv3HgVL24gzk/qLciv4z4nj4/wKg+ghEgP09KcL7ZHzO/A/vXPifVBj8gzbw+t8EEvk4VVT2sQWs/IQXvPXcmPzvEaTc9q/19PwiEdz8UhSY+YUCkvHSASD4ivDc+WY+dvip9cj3euW4/5FL7viDV7j3BjQk+ZlZaPyfTDznP3Ha/LZKHPtnrAjqK5Xw/at8TvsbbkTx3oV09k00cPj7vtD6Z6m+93ctrP72xEb8PEBW+i/FMvqq8SD8KuQ85z9x2vyyShz7r6gI6qtXyOyKnrz1fjmA/jzw+P0dNKL4Zcg++EiQiP9uChL3Qr36yHFjkMK12fz83eXY8QKupvDG/0Tsv6X8/XmK8PQV3gb2/HZw7xmV+P8i2lTyMh1s+99ZevaedeT/Gaom92IlUPu7uxbw6wnk/CHkZvxk2v74v1cm+NYYWP7Nznj6mEyM/CUGZvvCvIz+QeK8+lI/svoppTD53EUs/HUNWPc28N79afKC90p4wP6i3Ir+N+J4+QcCoPoERID/mf2i+hpgzv+ob1T7UMQg/V9a8Pk57A752CVM9IE1rPxoF7z08Jj87umk3Pav9fT/Lg3c/zcYmPjOBpLymTUg+1qI3PiVWnr4vr3M9+ZhuP4Qy+74f4/E9jRcKPtNMWj/z0g85z9x2vy2Shz7h6wI6iuV8P2rfE77G25E8d6FdPZNNHD4+77Q+mepvvd3Laz+9sRG/DxAVvovxTL6qvEg/CrkPOc/cdr8skoc+6+oCOqrV8jsip689Xo5gP488Pj9HTSi+GXIPvhIkIj/bgoS90K9+shxY5DCtdn8/N3l2PECrqbwxv9E7L+l/P15ivD0Fd4G9vx2cO8Zlfj/HMZw8b2FqPoUybr0Dtng/3WmKvedARz7m5rK8mXJ6Pwh5Gb8ZNr++L9XJvjWGFj9N0Z0+WDAjPx9hmb4MsyM/5YCwPpc87L5HiU0+LN5KP5PXqT0V8Dm/t0auvXVQLT+otyK/jfiePkHAqD6BESA/KoZjvrDiM79qQtM+IA4JPyncvD5LqwK+obtRPV5Uaz8hBe89tyY/O7tpNz2r/X0/y4N3P83GJj4zgaS8pk1IPtaiNz4lVp6+L69zPfmYbj+EMvu+H+PxPY0XCj7TTFo/89IPOc/cdr8tkoc+4esCOorlfD9q3xO+xtuRPHehXT2TTRw+Pu+0Ppnqb73dy2s/vbERvw8QFb6L8Uy+qrxIPwq5DznP3Ha/LJKHPuvqAjqr1fI7IqevPV6OYD+PPD4/R00ovhlyD74SJCI/24KEvdCvfrIcWOQwrXZ/Pzd5djxAq6m8Mb/ROy/pfz9eYrw9BXeBvb8dnDvGZX4/xzGcPG9haj6FMm69A7Z4P91pir3nQEc+5uayvJlyej8IeRm/GTa/vi/Vyb41hhY/FBedPolPIz8XpZm+yrAjP4GPsT6K4uu+tKlOPv6qSj+RJdM9QCs4v5KZtr1JWy4/qLciv434nj5BwKg+gREgPwHSYL4KCjS/yz/SPhCFCT9N37w+YDoCvkgGUT1HWGs/JgXvPRUmPzu2aTc9q/19P8uDdz/NxiY+M4GkvKZNSD7Wojc+JVaevi+vcz35mG4/hDL7vh/j8T2NFwo+00xaP/PSDznP3Ha/LZKHPuHrAjqK5Xw/at8TvsbbkTx3oV09k00cPj7vtD6Z6m+93ctrP72xEb8PEBW+i/FMvqq8SD8KuQ85z9x2vyyShz7r6gI6q9XyOyKnrz1ejmA/jzw+P0dNKL4Zcg++EiQiP9uChL3Qr36yHFjkMK12fz83eXY8QKupvDG/0Tsv6X8/XmK8PQV3gb2/HZw7xmV+P8cxnDxvYWo+hTJuvQO2eD/daYq950BHPubmsryZcno/CHkZvxk2v74v1cm+NYYWP9FUmz7j8iI/1sOlvv5/IT8vJ7Y+HxnhvnrFRz4DIk0/T+8WPg39NL+qcZO91RwwP6i3Ir+N+J4+QcCoPoERID/3oV++HRs0v+bN0T4juQk/q+C8PtEIAr6+tlA9/llrPx4F7z3HJT87umk3Pav9fT/Lg3c/zcYmPjOBpLymTUg+1qI3PiVWnr4vr3M9+ZhuP4Qy+74f4/E9jRcKPtNMWj/z0g85z9x2vy2Shz7h6wI6iuV8P2rfE77G25E8d6FdPZNNHD4+77Q+mepvvd3Laz+9sRG/DxAVvovxTL6qvEg/CrkPOc/cdr8skoc+6+oCOict8jsDrK89Xo5gP25HPj87iCe+J8oOvlUtIj/ZgoS9N3jBMq9u+DCtdn8/93h2PGqrqbxAv9E7L+l/P2VivD0Ed4G9fh2cO8Zlfj++MZw8b2FqPnkybr0Dtng/3GmKvelARz7/5rK8mXJ6Pwh5Gb8ZNr++MNXJvjWGFj8+eZM+HQwlP3vcmb5LIiQ/h1HJPkPJ1b7XIFQ+XuRKP9pzAT4NbTu/yuFMvWzeKj+otyK/jfiePkHAqD6BESA/bVdfvkkfNL/tsdE+5MUJPwPhvD6n/AG+X6NQPWlaaz8uBe894iU/O79pNz2r/X0/7YB3P5WmJj6DYaS8gqFIPiumNz7sWZ6+MLpzPSSYbj8IF/u+6eLzPdJWCj5USVo/H9kPOc/cdr8tkoc+Vu0COlvpfD/mnxO+/pyRPIT0Wz22/Rs+QPS0PpVzb72vzms/c7sRv8UWFL75mEy+y8ZIP2nFDznP3Ha/LZKHPv3qAjpF0eo7y+CvPV6OYD/gvD4/XfceviZ9B75ukSI/3oKEvQPsrLHoPxqvrXZ/P66FdjyIAqi8McvPO3rpfz8YZLw9xzOAvVOvmjtTaH4/DGabPOIkaD5QCGy9wNl4P2HYiL3TSkY+0MWwvKGCej8HeRm/Fza/vjLVyb42hhY/C0mZPsejIz/Tf6C+q50iPwHiwD5p0+S+uF5cPhFGSD9GE+w9dwI3vztFn72Kbi8/p7civ434nj5CwKg+ghEgP/Q2Yr7s8jO/49/SPmNBCT+52bw+KAIDvvNGUj1aUWs/HgXvPcQmPzu+aTc9q/19P8tjdz/jpiI+tG+gvPwhTj4ArDg+LeqWvldoaD1+ym8/sxz7vo897D2l2Ac+W4JaP8PaDznP3Ha/LJKHPg3rAjqaE30/1cgQvvLPjjxuOkk93GkYPmYutT6nIWq9SO5rP5whEr/LQAm+17hIvjQ2ST8dvg85z9x2vy2Shz5V6wI68NvdOz02sD1djmA/T3o/P+8HEL7GhPW95DIjP9qChL0q4akxiAjArq12fz9cN3c8mvSQvLmhtDtI7X8/uXy8PfJKXb0Sz4Y7LIl+P3TxkTzc7Eg+tZtNvSWnej+q4Wa9fuI4Pj8Slbz1VXs/CXkZvxg2v74x1cm+NYYWPwcUlD464yM/K7Crvkq0ID/ZI9g+1oLMvsW6Wj4PBkk/Rs3ePd3UN78IzHq950UvP6i3Ir+O+J4+QsCoPoERID/ES2++eB4zv/gx2D5D3QY/Ari8PjmkB77Htlk9VidrPyUF7z05JT87tGk3Pav9fT8GNnc/vnIZPqBbl7w2eFg+WqQ6Pm2ahL4XF0w9zXxyP4zX+74kJ8o9/OP/PXQhWz/o2g85z9x2vyyShz5/7AI6bFt9PxOJC76Book8XmkoPQ7UET63m7U+QVdgvVslbD81vRK/1cPsvVfaQb4x8Ek/WsgPOc/cdr8tkoc+1OoCOswZzjsBkrA9XI5gP2BEQD/NLfy9Ze/WvR3fIz/ZgoS9BCH3MRhSYLGtdn8/z4h4PCT8TLxdkYI70PJ/P/GpvD1+lRy9rFFEO+24fj+Wuoc8MOIOPogYFL2CSn0/QCUcvfT5Hz4s7FK8kKV8Pwl5Gb8XNr++L9XJvjWGFj+Kz3c9nBAxP6fwx74hwho/us0pP/2hWL6cxVA+hzIwPxhaZDw/KiS/HvdqvcDZQz+ptyK/jfiePkDAqD6BESA/00uBvizFMb/w5d8+VTsDP1aEvD6vcQ6+uqFkPfLmaj8hBe89wSU/O9VpNz2r/X0/PgZ3P9fvDD5iBIu8lzJkPuxhPD6/8Fi+y20mPQR/dT8Xsvy+xV+ZPR516j1v4Fs/+tMPOc/cdr8tkoc+4+sCOouufT9NrwS+iuCCPIJ8AD2XLwk+Ly62PhN7U73YZ2w/sU4Tv4d8v70TaTm+usRKP0PFDznP3Ha/LZKHPh/rAjo+tr47sN6wPV6OYD8/7UA/RI/ZvcBtub0LbyQ/3IKEvWI3KzFQoSQvrXZ/PwkVejxMNtq7G+UTO7/2fz/c3bw9ffimvCK+4jr22n4/LiOIPDCGmT0LDKK8qzF/PwFAoLzjjAM+q8YBvD3SfT8JeRm/GTa/vjHVyb40hhY/IGxsvpCjNT+PVsC+nrcMP0gnPD+KyQK9qCMTPdsnLT/3p7O8q++xvm9QA76ruG0/qLciv5D4nj5BwKg+gREgP8Zoi77iMTC/YcfnPpCT/j64S7w++4gVvqUDcD1koGo/JwXvPUYmPzu/aTc9q/19P9Lgdj/Fm/89UiB8vG9abj5BST0+zyUovkpYAD3863c/0Uv9vtf2TD0NvtQ9wIJcPy/ZDznP3Ha/LJKHPt7rAjqm+n0/Ev/6vdKTdzzDA7M8QRQAPm7Ktj7W5UW9KqdsPyqwE7/F5JO9dgkxvh+HSz/ZuA85z9x2vy2Shz4Y6wI6lQKzOz4RsT1ejmA/0VtBP/pzv71+LaO9Sc0kP9yChL1+NwAy4IaELq12fz8OYns8MyL5uix3Xjol+H8/Ewi9PfcxwLsM3jY6GOd+P/UnkTzYCrY88eLIu0zkfz9FtMu7uYTYPfuhi7vZjn4/CHkZvxo2v74x1cm+NYYWPzVfpr6mYjE/5AvPvnExAD8fLQQ/ngZkPcK8Cb3smlo/AfhsPeeni71lC6e9Lh5+P6e3Ir+P+J4+QsCoPoERID++VZO+hNcuvz7R7T7eMfg+hR28PicTG77P53g91GZqPyAF7z3EJT87xmk3Pav9fT8MynY/bMfqPbiUZ7wBK3U+smQ9PodkAr7M+cU8vWJ5P3iO/b6MA/o8dvzDPXPpXD9v1w85z9x2vyyShz6R6wI6/TB+P0Bd7719Gmw8H6FuPGU88T11Src+y7w6vTDWbD+T2xO/iSRmvfuRKr6WFEw/+cAPOc/cdr8tkoc+QOsCOsM5rjv7I7E9Xo5gP7aEQT8Y1LS9Tx+avSPwJD/bgoS9udJ5sVSKwDCtdn8/7fJ7PN0cAjlLSII5QPh/PxsavT0M3qM5tvCGOQfofj+DYJc8yUx4uWsifrnP9H8/qeKKunuixD1e4zG79NB+Pwh5Gb8YNr++MNXJvjWGFj/C7ZO+AZQsPxta/L4zru8+ZEqLPqaNJT2dZTu8Chx2P5/GGD6lzdU7nvSivPsTfT+ntyK/kPiePkLAqD6BESA/sqKWvko/Lr+pS/A+BXz1PswJvD7BYB2+I5p8PUNOaj8qBe899iU/O8lpNz2r/X0/TcJ2P2gT4j3u/l680rd3PlBKPT4sleW9XNStPBHjeT/NnP2+AU+3PIoRvT3LDV0/BtgPOc/cdr8skoc+gesCOlxGfj8LZ+q9kDVnPJBXPTx6yeo9lYG3PjvnNb006Ww/w+QTv+NxS7305Se+tk1MP8u4DznP3Ha/LZKHPiTrAjrQDde6IjYsPmrKBT8jkFA/+OLCvUTph73tchE/14KEvcRQATIpbiGxrXZ/P634Mj5pwSY5vTQXOUcPfD8NC4A+9+TiOQvEIzmH3Xc//bwQvpRbormNeye5CW59P/wyV77Zao09NRQhvXR0eT85PAm/6f7ivsuQ6r4Spw0/gSgBPupSIT/ImRG/zWgDPx+YgD4/nNW+JRr4PfNuXT8fG9k99OvQOwRT0rynd34/2wIqv9ZhyT4Qwao+WpQKPxG8QT3dVSS/huATP2GDAD9Co7s+bNYoPnN/h719zmk/NQXvPaklPzuzaTc9q/19P9MhID/fElo+aBrXvCwIQD/+WUw/dCLbvMGJET11xhk/uoQov6EE+zxEWRI+Fws9P4baDznP3Ha/LJKHPg/sAjqyik4/3SnOvulaSz2l5ts+BapMP26VKD5a1YG+SuIEP/9+V7+WUM29ndgjvst2AT+TsA85z9x2vyyShz4S6wI62nbDvGiaaT0qtV4/UYcpP2zloL3RBci9wR49P9mChL2tHpSxQBmOsa12fz+QgZI+JLZSO8ONtrxeOnU/EDVPPnXwKrzf0QS9bY16P58m370s3zU8PJzrPHhafj+vYZ6+03yuPb1RnbsmdnI/CYQXv/M4yL7zDvO+i14FPxLh/L0XvDA/V1byvlV0CD+enq4+SNhevt3DszzfC2o/K7LOPRuEtryi6fa8FYN+P7ARLL9K/b8+KqWyPvXfCD9qyUi+iBkrv5uyCT98JvM+K+yTPTqPy72ZIcA7UQ5+P4h58T0MKlM8Lvc6PZXsfT+2X28/HnpPPp2mzLyYY5Q+PBAdP/4zi73nX0k9IANJPyC30b5CsNo8L00UPhN6Zj8OzQ85z9x2vy2Shz6P7AI6Tvt7v8f2MT4wiq+8zyy0vCLezz5iL4s+VdP6vZEmXT8vVPa+adzRvbypAL6ijVw/DcYPOc/cdr8ukoc+8+kCOo4jIL1Mfxc9Vp5hP5jxDz8Itpe9AKwVviOATz/cgoS9WYyZsTwGBbGtdn8/G0qqPrL29jyLrKS6V01xP4D+Uj4wSzS867VMvfMpej/v2FC9HoyLPD5ZAT2BgH8/hP/tvazMqD1d3AS9n0B9P+LYGb+ll7W+DNK+vqyWHD98QY6+5tg4P+Dher61lBU/TZHmPoIAB76vSLu9KNpgP0fGlz3v1hG+Qq1QvaJXfD8MFhm/Zbq8PmhHrT6sRyA/sSUQvvCnM78hH9s+YEUNP6HzhjyngJG+7wagO9VndT+UsPk9yQpNPTjsRj1Pdn0//zRWPyjFxT6CE0O9pznFPmU5bz/44X479g5AvDMvtj4HmLW+/WAoPphmfz6Mz2I/scEPOc/cdr8ukoc+NuwCOns8cD+Puky+o/DJPJ61jz7falc/OfqsPTJhCb5ZOgQ/X3advmMIKb75I6G9WQ1vP6XLDznP3Ha/LZKHPhrqAjqS6DK9PGMOPWx9Yj8Y0gk//jSavcSdJr62y1I/4IKEvbzaDrJ83NcxrXZ/PyuPuT77bSA9Kml1OxFibj8BeXQ+0huJvMzja71mH3g/Tvdhvfg8vTyGwAc9nWZ/P7YLhr1kYaU9cF06vb5Yfj/5kRi/nwqivvPHmL7Iyyw/1+yOvr6POT/eaCS+4+cbPzcq5j6arUa+eUpivT3EXj9aN0k9ztFqvinzir30QHg/070Qv19duz6IrKs+a6UoPxUxVb2fUzS/S27LPoP7FT+og4g8c355vgw0iTsKP3g/UIb8PayQhD2zE0s9BDB9PwyyST8o4vE+r5ZuvYQOyD7qCXY/52KfO5ITi7w6JY0+aRC0vldudz6Pq1g+cBlhPxHNDznP3Ha/LpKHPqntAjoV0WM/0io/vjWQvDyzwtQ+2DduP75tKT0phOO97mSxPs3ImL7bcUi++hKjvadFbj/hzg85z9x2vy2Shz7q6QI665AyvSmfDz19ZmI/4mwKP2Gnm70hfCa+lmNSP9KChL2ETQ+xZBQZsq12fz/C8cQ+zGgYPS7C0Dh4HGw/uKqHPvu8wLwY9HC941B2P5VXpb3tSeM838cMPebpfj+yt7q9O4mrPaLCQr0bvX0/X2gYv1eqoL6zc5a+0sQtP6FQlL6ySzk/whsvvu05Gj/aeeA+xL2EvgvdXrydRlw/H0pCPVtGcL6RKo295e13P1IoEb+18Lo+2SKsPslJKD8PiMm8bhc0v/ETxz4/Kxg/r56KPHLGMb5bhUM7/xJ8P06G/D2ykIQ9uRNLPQQwfT9zVUQ/+Dz8PkXNeL0NPtA+pZx3P6a/5ztgiN68bzGBPnmOsb7r5Ig+0HtQPuMrYD+B2w850Nx2vyqShz6R6QI6Ar9dP5nCR771CcU8rTnrPr9kcj/rOxA9/trjvW16mT5+4Je+AJJPviQ8nb3aGG4/WrMPOc/cdr8rkoc+hvACOnzDMb0ZlBI91jBiP5bcCz9zrp69Ai0mvrJqUT/VgoS9hj0qs6ZaDDKtdn8/95zNPnERET35Uxe7HkZqP7/zkT6KcfG8Q9FyvdLKdD8UhM29uRgCPWALDz3Da34/ahnjvRKzsD1JUUu9VCR9P19oGL9WqqC+s3OWvtLELT/Kxpi+Zd04PxBbUb6v8xY/2Q7WPspCn74vqLc8QmtaPwZKQj1gRnC+miqNveXtdz9DAhK/rBC6PuoUrT7WjCc/JTZnu2uRM7+OS8Y+3SoZP/C5izyCfve9fBsIO/QVfj8O6vM9Aod/PVWKRT0EYH0/XNI/Px8jAT+DwX69LVrZPhO8eD9V1Rs83roiveyVbj553a6+p2qSPlwaUD5QN18/b8wPOc/cdr8ukoc+beYCOu1kVz+4TE++zXnMPKgeAD9MIHU/BsX9PN135r1eAIc+tK6TvrbuU770oZi9GpBuP3PODznP3Ha/LpKHPg7sAjrnwDC9nQAWPeDzYT/UfA0/2LWivZbBJb5FS1A/14KEvaZLkTJl84CxrXZ/PzRf1D60XAo9fPpzu8PGaD/h/pk+n0AOvR7vcb3kg3M/UvvsvQVcED3/1w49n/Z9P51WAb7j57Q931BUvbaXfD9gaBi/VKqgvq5zlr7TxC0/4FKavss9OD/2L3m+BIATP0WWyD4/Ira+JNpfPZHEWD8RSkI9X0Zwvpgqjb3l7Xc/kysTv3bbuD7/Xq4+7YcmP16lfjy+1DK/U6zHPmCIGT/DR4w8m3WovUBGuTo2GH8/+g3cPQRVZT3A1jU9Gdx9Pz34Oz9XPQM/pHOBvbqL4T6Rfnk/K6U8PJJ5U71c5V4+67WrvukBmj7SyVI+amReP1zHDznP3Ha/LpKHPtTtAjocWlE/TNFVvp3n0jxuIwk/K+B2P2r/5Ty5E+q9QaxyPmqjjb4uS1a+adaUvSVibz/ewQ85z9x2vy2Shz6R6QI6PZ0vvZWVGT1utWE/wSYPP95Xp72CQCW+Ih9PP92ChL3Q6u+wujlWsa12fz/RCNU+hCEGPenLh7tcomg/u7maPtynGr0k/XG9qF5zP1Lx770kExk9UzsPPS3mfT/c5AK+6LC4PaP4V73UfHw/YGgYv1iqoL6tc5a+08QtP8Ugmr6X3Tc/b2mGvh7bET9RSro+L0vBvqD7mj15IFk/KkpCPV1GcL6XKo295e13P/SFFL/mbbc+aN+vPktTJT/9MNQ81Hkyv0yQxz614xk/rleMPC0Znb2Rx6w6NDV/PykNuT2v+D89aeUdPaR6fj+40zg/ZZ4EP+TPgr3NjOg+UP15P1QJVjyKFn69gdJSPiJ1qL64zp8+03NXPva1XT/RzA850Nx2vyyShz7s7AI6Yv9LP8A+W74zQtg81ncQP2n2dz8TkdY8NUvuvZteXz4hI4e+uFNXvhp4kb2uS3A/qMIPOdDcdr8skoc+qewCOqpnLr0BKB09lnhhP9nGED/hOqy9bLAkvjn0TT/XgoS9WrrSskrPOLKtdn8/2unUPi1/Aj2gJoW7iqtoP/aCmj7qEiW96ZtwveBhcz/EMe+93jQgPa0yDj0u5X0/VZACvrW2uz1Q6Vu9P3N8P2BoGL9VqqC+rnOWvtPELT9ZPJm+q3M3PxEskL7rRRA/uvWrPi26yr7z3sE9fHFZPx5KQj1bRnC+lSqNveXtdz9L9RW/zOO1Ptt2sT5hBiQ/Tw8TPdX4Mb/PBck+4N0ZP9ZSjDzxmqC9naKwOngsfz9k7o49casUPdhw/zzxFH8/0WM2PxZ2BT+opIO9ZjjuPtJNej9x3Gc8htiPvezjST4fcKW+f/ijPqkmXT77Kl0/rMkPOdDcdr8rkoc+k+kCOpabRz93iF++/HzcPAwTFj9lmXg/t5LNPK2/8r2ZnVI+WUaBvoSYV74lSY69gx1xP2zSDznP3Ha/LZKHPt3uAjpvMC29ZpQgPao/YT8+ThI/CQaxvd0ZJL4e1kw/2YKEvU0diTFg5GUyrXZ/Pzzd1D7Me/48+xdwu1ewaD/IYpo+42UuvTjlbb0lY3M/3MPuvcNOJj3n4Qs9KeR9P0xcAr7h+b09SZZgvQpqfD9gaBi/Vqqgvq9zlr7TxC0/qMyXvu3wNj91tZq+A5AOPzh2nj49vtO+Kr3lPSlQWT8YSkI9XkZwvpUqjb3l7Xc/0F0Xv3latD6LBrM+6rkiP38+PT1iSDG/YB7MPnl2GT+1Row8TRSpvUb0uTqSFn8/sdVDPZzJ0DxSwbs8gI5/P2ebND+t7AU/lhmEvf2O8j7zgHo/6plyPFttm72OokM+o+Civl6tpj4fFWM+3cJcP2HIDznP3Ha/K5KHPm7vAjpyTkQ/BbNivmGc3zwLExo/rO54P1tiyTykD/e9CP5KPvuDeb7Kgle+GEiLvdO9cT81uw850Nx2vyqShz7L7AI6ZwssvSe0Iz0CDWE/xa0TP3Fctb0MiCO+UdFLP9iChL0gWJ8y7h6EMq12fz9y6dQ+oPb4PAS0Srsur2g/NGKaPhdQNr0VhGq9uGBzP67L7r3IRis9dOgIPV3ifT+wXQK+sY6/PflnZb3hYHw/YGgYv1aqoL6yc5a+08QtPxf7lb6xXDY/GyelvqHYDD/mtZI+HOnbvptXAj5CzVg/HkpCPVtGcL6WKo295e13PwijGL/z8bI+5260PgSJIT8ES2U9NXgwv9Rp0D7uvRg/pjWMPAF1tL2MeMY6Yfd+PynF2jw1Tn880YlvPKnZfz+DYTM/OiIGP3FOhL1LtfU+PaJ6P3SFdzyaB6K9eZA/PjvioL6PLKg+a5RoPit8XD+Byw85z9x2vyyShz6J6QI6SABCP4PkZL5MxuE84MMcP9sSeT/kZMg8beb6vWYERz4omnO+8EtXvt+8iL0ZJ3I/jb8POc/cdr8skoc+EuoCOi4PK73IXCY95eJgPzrVFD/I6Li9UAgjvpTzSj/fgoS9it+VMawtaTKtdn8/CwnVPqKm9DxaGCS7NaloP+V7mj7ZgTy9WC9nvRxbcz9NNu+9ewcvPXLwBT3R330/R40Cvo+RwD1wumm9TFh8P2BoGL9VqqC+rnOWvtPELT+zBJS+s8Y1PzeOrr5xRws/LWuJPiKt4r7giA4+6RlYPyNKQj1bRnC+kSqNveXtdz9zqxm/wcixPsGTtT6OjSA/BOCDPX2eL7/hTtU+EdAXPwcijDxuqcC92eXTOqbTfj+mSg88cfD1Ow0p7zvn+X8/bJUyP4sxBj+IXYS9h+P3Poy4ej8bfHg8HdCkvTkgPT6WeJ++4M+oPnogbT4jUVw/rNkPOdDcdr8pkoc+iewCOiB2QD/JWWa+dDbjPISEHj97HXk/oQfJPAoh/r2ZJEU+AadwvqwLV77V8Ya93F1yP0nQDznP3Ha/LJKHPnnnAjoZWCq9Ik8oPbzEYD+5qxU/NFO7ve+qIr5nUUo/5oKEvZDsBLCOxl8yrXZ/P7Q21T4yy/E8QbUFu5OfaD92qpo+s6FAva6VZL3xUnM/Ae/vvYhyMT3ZmwM9o9x9P/HjAr5fGcE9NO1sveNQfD9haBi/VKqgvq1zlr7SxC0/J0WSvrlINT8LyrW+PxAKP5hEgz57bee+yqEWPjF0Vz8xSkI9WkZwvpAqjb3l7Xc/3F0avyD+sD5IWbY+DOIfP3aCkD0E3S6/7OvZPkjdFj9CEIw8SwvLvS1R3zpms34/iE94u+HdBjupdgY7Qf9/Pz8fMj/KLQY/31mEve4++T5Oxno/sXR3PB8+pb235Ds+XaCevpruqD6MRHA+0jtcP/3MDznP3Ha/LJKHPhHjAjoeI0E/fZRlvutz4jzRwx0/o8B4P68j0jxErgC+ZC5LPvtrcr7NMle+yHKFvchCcj8O4Q85z9x2vyyShz5j5QI65gwqvbshKT02uGA//QUWPw0/vL26hCK+AA1KP9uChL3XkyWyRTYrMa12fz8xbdU+9aLwPLEN8rppk2g/1+iaPqhWQr2JZ2O9xUhzPw/j8L05ajI96o0CPeTYfT+uWgO+Uz3BPTlfbr09S3w/YWgYv1aqoL6tc5a+08QtPz1bkb62CjU/gi65vop+CT8n74A+AIPpvjLNGT6RGlc/G0pCPV5GcL6SKo295e13PxehGr9WsbA+taO2PgehHz8CUJY9Tncuv0Jq3D5JVBY/EwmMPEIQz70ZvuM6dKZ+P8I5DbwTCyI1c/XBs5H9fz899DE/SigGP2tUhL2yxfk+cMt6PxWXdjy2AKW9rYU7PmhVnr4q5Kg+sn9xPsM1XD/S2g85z9x2vy6Shz6o5QI66OxCP12mY75yjOA83robP1Q5eD/o9N08UbQBvth2VD5EXnW+5pVXvoKJhL3LD3I/gdoPOc/cdr8skoc+XOcCOuYMKr27ISk9NrhgP/0FFj8NP7y9uoQivgANSj/bgoS915MlskU2KzGtdn8/MW3VPvWi8DyxDfK6aZNoP9fomj6oVkK9iWdjvcVIcz8P4/C9OWoyPeqNAj3k2H0/rloDvlM9wT05X269PUt8P2FoGL9WqqC+rXOWvtPELT89W5G+tgo1P4Iuub6Kfgk/J++APgCD6b4yzRk+kRpXPxtKQj1eRnC+kiqNveXtdz8XoRq/VrGwPrWjtj4HoR8/AlCWPU53Lr9Catw+SVQWPxMJjDxCEM+9Gb7jOnSmfj/COQ28EwsiNXP1wbOR/X8/PfQxP0ooBj9rVIS9ssX5PnDLej8Vl3Y8tgClva2FOz5oVZ6+KuSoPrJ/cT7DNVw/0toPOc/cdr8ukoc+qOUCOujsQj9dpmO+cozgPN66Gz9UOXg/6PTdPFG0Ab7YdlQ+RF51vuaVV76CiYS9yw9yP4HaDznP3Ha/LJKHPlznAjoofyW9gV0pPfClYD84ZBY/4B/AvUpoH77830k/2oKEvRjEoDGcSkYyrXZ/P1vp0j43suU8WrsYvNIlaT+oa5g+VjhRvfrHdL0kkHM/EEXnvQ8wQj3tuxU9gOZ9P1TG+b2M7Mw99+VjvZRkfD9gaBi/Vaqgvq5zlr7TxC0/7t2Rvt9wNT84NbS+U3sKPxZGgj7rXOi+D4EaPnguVz8eSkI9YkZwvp8qjb3l7Xc/FqEav1OxsD61o7Y+CKEfPzVhlT2s/y2/6tHgPjBAFT99ecs8+o7ivSFUNTsqWX4/zDkNvAkABzXwgbaykf1/P2fqMz9+TQY/HXmEvQTD8z438Xo/d/0wPC9AZb1T80E+HMqhvnxgoz5lJmk+qy5dP6TKDznP3Ha/LJKHPg7nAjqJlEU/ux5ivigK3zz5fRg/r2h3P4Um6jxQdf29HaZkPip9eL7V3lm+eMuGvRS3cT8K3Q85z9x2vyuShz5C5wI6DwsavRYAKj3wemA/mE4XP2CDyb3wgBe+fG1JP+OChL0lZT2xBNylMa12fz8+n88+peXbPB+hrryp12k/ne2VPu6BXb1lpYG9ONlzP4Uj3b0ARlI9YgcqPQPxfT/0eeW9/8fYPRn3Wb3Mknw/YGgYv1eqoL6xc5a+0sQtP1Kfjr40zDU/1hCyviGMCz8qWYU+FDjnvvpTHT4B5FY/KUpCPWJGcL6ZKo295O13PxehGr9VsbA+tqO2PgehHz/1IJQ9pFYtv8TA5j52xBM/BWAuPdBi8L25D6U7Uv59P+E5DbwEkgg1Kl9jMpH9fz9OkzY/cdgFP6wFhL2vxew+mPt6P5V7jDs3WrC8ZHtIPqM3pr6wZ5w+iYZdPnVdXj+ayQ85z9x2vyyShz5v6AI6SERGPy3vZL7Z0OE8iVQXP4/sdj/+Kuc8+rjsvbw4cT6GgXi+EfRdvhzajb0pa3E/MdoPOc/cdr8tkoc+pecCOmK6Cr2z+So9zkdgP9CCGD/pRdW9+8IMvg/RSD/XgoS9bOv2MLT/HjGtdn8/3STMPl5Q1DzGARC9HIFqP8HMkz7DCma9G8aGvVIZdD/e/tO96lRgPYhrPD0x930/5nvNvRUj4z2xH1K9p8d8P2BoGL9WqqC+sXOWvtLELT+J/Yi+BhU2P/wfsr6FkAw/ImqJPjoh5r46aSE+Q1pWPxZKQj1fRnC+lCqNveXtdz8XoRq/V7GwPrajtj4HoR8/VJiRPaqjLL/f7+w+hSsSP7Lvfz2eEfi90lv6O4OafT/eOQ28k8wJNShAk7GR/X8/olc5PxXSBD/gAoO9lG7mPvS6ej/xmUe7du1xPKEfTj76f6q+G3aVPoK7UD7WhF8/49YPOc/cdr8skoc+P+oCOnWjRD9WSGu++BPoPFbUGD9aD3c/29PSPGjV1L0S03Q+MEd2vqjPYr6OTZi99C1xP/fdDznP3Ha/LJKHPlnmAjqTb/W8nCIsPSkaYD9wvhk/+j7gvUs0Ab6cLEg/34KEvUsDUrGmT60xrXZ/P2sjyT5+zs88NtJEvdMBaz+SY5I+6vZpvXcNib3qRnQ/wWnNvd4waj3etEk9ufl9P3Cctb2jTOo97e9NvQz6fD9haBi/U6qgvqxzlr7UxC0/bWaCviVBNj86v7O+vWMNP46yjT7uNuW+2uslPjSvVT84SkI9W0ZwvpMqjb3l7Xc/GKEav1SxsD61o7Y+B6EfP16EjT01Eiy/2BPyPlHKED/q6Jw9kkn5vQtoGjyrU30/1DkNvBt+DTXyoYOxkf1/PyKjOz/vhQM/RLuBvV/74T5MR3o/FvIevBZtPT1MxlE+IOCtvmvWjz6gr0Q+1XhgP5vHDznP3Ha/LJKHPtznAjrnOUE/AONyvveT7zy5Yhw/I8F3Py1KsjxcVbi9yrlvPrqwcr79/We+0TalvUf3cD9i3Q85z9x2vyyShz4O5wI6XlfavPIkLT1h+l8/9sEaP9ly572ure29a6pHP9uChL1kW7ay7TqjMa12fz+bTMc+PSXPPLd0ar2uQ2s/qQKSPk+eaL1Z0Ye9dVl0P6nryr3s3W09nr5OPUX6fT+7oqG9uZ7sPUvETr3sJn0/X2gYv1aqoL6pc5a+1MQtP8mTeL7wSjY/bVG2vnzkDT+MbZE+yKfkvusVKj56AFU/I0pCPVpGcL6XKo295e13PxehGr9WsbA+s6O2PgmhHz829oc9/c8rv0jz9D5t+A8/wS+hPXb3871eNRs8nV19P9A5DbwMQRA1SI9+M5H9fz/C7Dw/wmsCP/GkgL1LR+A+rut5P9HaaLx6R4o9ZkhSPufcr74Eo4w+dR87PiMaYT8Qzw850Nx2vyuShz5o6AI65Yg9P0Ibeb6EtvU8JzwgPzGQeD+nQ5E82AKcvamQZz498m6+hrFsvhVVs72XwXA/FNoPOc/cdr8tkoc+F+kCOpupyrz+dS09QO1fP+lMGz8Z4+e9zm3fvUt+Rz/ZgoS9pUV8sTgMpjGtdn8/RKTHPteg1Dxw2XK9XCdrPxFLkz4wPl+9MyGBvW0/dD9tUc+99FtnPWTbRT0n+X0/EH+WvZba5j0zOFe9oFB9P2BoGL9WqqC+q3OWvtPELT+mQW++WiE2P45Bur7p0g0/JciTPkfg5L5fRi0+QWBUPxFKQj1bRnC+jSqNveXtdz8XoRq/VbGwPrOjtj4HoR8/U32BPXAULL+z/fM+xSYQP7ZmmD36nuS9wFsJPDStfT/KOQ285HcPNULGGzGR/X8/vKw8PyMBAj/IO4C9WxjiPj0Bej+DHHi8AwyWPTKQTj70+a++AveMPpbQNT7nTGE/ns0POc/cdr8skoc+KegCOm+COj99p3y+Yjb5PK9mIz+yUXk/qDpuPELPhb1rE14+NjVsvl7Qb7476MC9bZFwP3jdDznP3Ha/LJKHPuTlAjp0+Mq88KcsPY7zXz8OOxs/1QvgvbyU2r12xUc/4oKEvSiR1LEIqqMwrXZ/P3I6yj6Ik988C3dZvRewaj+s95U+MndPvRpObb1o+nM/a8rZvT54Vz2SwTA9o/N9P8fXlb211Nk9IktlvfRzfT9haBi/Vqqgvq5zlr7TxC0/p8tovuHJNT88XL++9zsNP+MIlD4X7+W+spwuPjr6Uz89SkI9XUZwvqAqjb3l7Xc/F6Eav1exsD6zo7Y+B6EfP0Mgdj3Cviy/c/HvPo8jET/4pIg94p/NvVoq3TuPIH4/5DkNvPzlFjWYAbIxkf1/P/nVOj88aAI/d6GAvTU05z5mkHo/0w1KvG8/fT30uUc+HvatvgXnkD6AazU+PhZhPwjMDznP3Ha/LZKHPrrqAjok8Tg/cTl9vl3G+TwoHiU/lel5PxQLUzw8HXi9aLtUPrnJa76ARHC+m6jLvVBtcD9F3A85z9x2vy2Shz7D6AI6Hr7YvCD3Kj01CWA/W6saPzTq0r1Yh969c1xIP9SChL2LeXwyoIepMa12fz9GEc4+QjntPKgtKb2F/mk/gzKZPgBCPb1RO1e9Lp1zP93h5r200EI9SoIWPfnmfT/yMp+9ApfJPc8mdL0ChX0/YWgYv1WqoL6pc5a+08QtP2icZb6RXzU/kmPEvpddDD/E1JE+mZvnvtphLT6D91M/80lCPVxGcL6RKo295e13PxihGr9SsbA+sKO2PgihHz941Gk9UJQtvy1T6j7sghI/LKloPUYctb0fh6U7LJR+P7k5DbzRqg81g8okM5H9fz8w4zc/gTYDP+hsgb3Vr+4+6E17P+eR4rsNZxQ9Poo/Phkdqr5BfJc+dNo5PgWDYD89zA85z9x2vyuShz576QI6l7g4P7aoe74NO/g8N4QlP+VSej9e5U88neB+vRlXTD40Wm2+PzxuvoGr0b1gYHA/odoPOc/cdr8ukoc+G+cCOhye8LwG+ig92CtgPya7GT9lZMW9SrLrveIPST/bgoS9lWedMfXsVTGtdn8/kBLSPvlA+jwwJd+8cDlpP1ctnD4b/Cy9kpNFvRM/cz+eK/O9TJcuPckG/Dwj1X0/HrW2vTuuuj0KAH+9lWh9P19oGL9UqqC+rnOWvtTELT/V0We++Pw0P+j9x75GXAs/M/ONPjpg6b75DCo+IE9UPzBKQj1eRnC+miqNveXtdz8WoRq/VLGwPrWjtj4JoR8/iXpjPR9dLr8EUeQ+uPsTP+bhOz1F3aG90KVuO1ztfj+6OQ28WmomNYzSaLOR/X8/aJg0PxrzAz/vJoK97fL2PovVez+oQ8i4J47tOe/6Nz7GKKW+2VafPs65Qz4RjV8/tM8POc/cdr8skoc+o+cCOgN8OT/ph3i+NCX1PDT2JD+Hgno/WIJjPFA+kL2ytUU+AHdvvq8ear7GO8+9/YdwP3rZDznP3Ha/K5KHPozmAjrgKQi9M9QnPWZXYD8Bhhg/6SO+vRFvAr7Emkk/3YKEvWHzHrIu/OMwrXZ/P4o/1T65SgE9y5JnvPuRaD8QHJ4+zuIjve5TPb0A/HI/JWb7vfSVID0AX9s85cV9P1LV1b25SbE9K9yBvVAdfT9haBi/Vaqgvqxzlr7TxC0/hBpzvmytND+GFcm+9SkKP6dliT6TrOq+X2clPr/tVD8XSkI9ZEZwvpYqjb3l7Xc/GKEav1SxsD6yo7Y+CaEfP4QhcT2s2S6/ZMvePgNsFT+BFBA99aKavemoLjsDHH8/1zkNvAofDjV+Ey8ykf1/P1oKMj9PdQQ/XaeCvW0v/T7P1Xs/G3XnO8XTIr2JQDM+1IGgvr2Mpj5kr1Q+hRxeP+rMDznP3Ha/LJKHPszoAjpVyTo/gwV0vpCy8Dya6iM/LGB6P/hbiDx/arC9ZaRBPjfyb76xOWS+qaG9veAUcT+a3A85z9x2vyyShz7w5gI6jl0YvTzbJz3DhGA/YVEXPyO0u71yKBG+YetJP+CChL0NXiEygAveMa12fz9Cv9Y+cQ0BPdNpo7sZQGg/Tj6ePkwhJ72szkK94u9yP8Cn/L25aR49EmXWPFXDfT+W8vG9afawPSRggL3uu3w/YGgYv1aqoL6uc5a+08QtP0CUgr4ynTQ/vefFviFVCT8oJoU+cPDqvkZAID5fxlU/OEpCPVtGcL6XKo295e13PxehGr9YsbA+tqO2PgehHz8wD4U9+/Muv7Rs2z4pYRY/+NbUPO5kpL0fIQk7LxZ/P8M5Dbz36RA1MgagsZH9fz/zvzA/huwEP/Mcg71FzP8+T2B7P/DMUjzplZS9RHIyPr9Znb6ZNKs+NyVmPuKyXD9WzQ85z9x2vyyShz5F6AI6SIo8P8u6br48eus8YmUiPxHueT8IV6U8t0LWveT0QD55qG++TsBdvlnapL3CwnE/9NkPOc/cdr8tkoc+B+cCOtvwJL2Unyg9K6lgPzllFj8fxLu9dV4dvjYJSj/agoS9k3FesUz7MbGtdn8/f7rWPn/++jzhgTK6B0RoP7X9nD4M/jK9bVVRvVgPcz+ke/i955clPSPu5jyay30/cCMCvqdMtz3blXi9IWl8P19oGL9WqqC+sHOWvtPELT8aqYu+I700P2zyv75uDAk/KgyCPiJ06r479Rs+GJVWPx5KQj1eRnC+mSqNveXtdz8XoRq/V7GwPrejtj4HoR8/b1CRPdfFLr+Smto+3LUWP24poDwSWbi9jpPnOkfpfj+8OQ28LQMHNdthGjKR/X8/Vt8wP16RBT+Qv4O9Uhf+Pn3qej8l1IA8SuCxvefWNT6NuZy+aMirPhILcT45+Fs/jMsPOc/cdr8rkoc+zegCOmU3Pz/9+Gi+gszlPLvGHz9aL3k/a6fDPNy69b0ueUY+LwhxvnzXWL6aq469gCxyP/ndDznP3Ha/LJKHPrzmAjrmDCq9uyEpPTa4YD/9BRY/DT+8vbqEIr4ADUo/24KEvdeTJbJFNisxrXZ/PzFt1T71ovA8sQ3yummTaD/X6Jo+qFZCvYlnY73FSHM/D+PwvTlqMj3qjQI95Nh9P65aA75TPcE9OV9uvT1LfD9haBi/Vqqgvq1zlr7TxC0/PVuRvrYKNT+CLrm+in4JPyfvgD4Ag+m+Ms0ZPpEaVz8bSkI9XkZwvpIqjb3l7Xc/F6Eav1axsD61o7Y+B6EfPwJQlj1Ody6/QmrcPklUFj8TCYw8QhDPvRm+4zp0pn4/wjkNvBMLIjVz9cGzkf1/Pz30MT9KKAY/a1SEvbLF+T5wy3o/FZd2PLYApb2thTs+aFWevirkqD6yf3E+wzVcP9LaDznP3Ha/LpKHPqjlAjro7EI/XaZjvnKM4Dzeuhs/VDl4P+j03TxRtAG+2HZUPkRedb7mlVe+gomEvcsPcj+B2g85z9x2vyyShz5c5wI65gwqvbshKT02uGA//QUWPw0/vL26hCK+AA1KP9uChL3XkyWyRTYrMa12fz8xbdU+9aLwPLEN8rppk2g/1+iaPqhWQr2JZ2O9xUhzPw/j8L05ajI96o0CPeTYfT+uWgO+Uz3BPTlfbr09S3w/YWgYv1aqoL6tc5a+08QtPz1bkb62CjU/gi65vop+CT8n74A+AIPpvjLNGT6RGlc/G0pCPV5GcL6SKo295e13PxehGr9WsbA+taO2PgehHz8CUJY9Tncuv0Jq3D5JVBY/EwmMPEIQz70ZvuM6dKZ+P8I5DbwTCyI1c/XBs5H9fz899DE/SigGP2tUhL2yxfk+cMt6PxWXdjy2AKW9rYU7PmhVnr4q5Kg+sn9xPsM1XD/S2g85z9x2vy6Shz6o5QI66OxCP12mY75yjOA83robP1Q5eD/o9N08UbQBvth2VD5EXnW+5pVXvoKJhL3LD3I/gdoPOc/cdr8skoc+XOcCOoDYH7upVik+uHIIP/ZVTz8ZncK9GT6MvZ4iEz/XgoS9eN2xMXDcJLGtdn8/Fp1PPmruTTqSDOC33a56P/Xwiz6Gray5p2OCuoNAdj/Gsie+LyPjOd9gITosi3w/fgHHvJm/bz2Zml69OBt/P5z4AL8gP+++xwHbvrBWFj8zsuc9f7IsP71V2r6Zghc/Ey0VPsn6+L4GIwc+efVZP0TkSz0ixWi+AhqKvYpfeD9buym/K+bIPmf6qj4ABws/eMwOvLOXNL9Y5bs+kzYbPwQ4Qz6S47i9VBWQPAczej/cOQ28mwcgNR0EI7OR/X8/TZohPwQlYT7jE968MUY+PxJWTT/yOe+8Mf8jPexaGD+G9Ca/eC0JPfheET7TcD4/4dgPOc/cdr8skoc+1esCOgAkTz/qMMy+12hJPQ+E2z7kbE0/szUlPp/nf772bQQ/j4RVv9DN1L1rYSO+go0EP4GyDznP3Ha/LJKHPvjqAjpYIAU7el0zPufJ3D7j7Fk/iKLLvX/UdL1wAQM/3IKEvY0zNDFGcZ6wrXZ/P+WRAj5ypBw5Fn07OQ3pfT8wZlA+O3/ROZEsRzlypHo/ejrAvRjml7n6g0O5rN5+P+t5Er2RjYc9O5M1vawFfz/y6vy+kAL2vqAg4r68EhM/48UFPhlwJD/pEgi/cVYJP5kgHD5UZtS++OvzPR6bYz/v5nM9GCNIvgEIer2pHHo/UOMpv76eyD74r6o+2QYLP3wYN72DnzK/abzaPqzBEj88JLw+g4uSvW5e5zwYRm0/6zkNvI+nEDVKYYsykf1/Pym08D73tVI+HdfPvIOfWz9A11w/ZQ2HO1Fg57vRdgE/5FElvzVMDDzjwVA+Vlo8P5vWDznP3Ha/LJKHPmHsAjpQWDw/gyiovhveJT18Rxc/QDFkP0XniT2+fRC+7dPZPs9IYb8PDNQ8T/hBvi6Z3j5p60U78K12vzLjiD56AKg6gmKNO6oXMz4x4PY+/rJdP1Mpz70Gsmi9ewb5PuSChL1h8vuwblfZMa12fz9gChU+9YwgObz6LTkgRn0/XJ5iPqZK2Dm+CTo5+aZ5Pw1S5b1a/Ju5WQs5udxjfj9Yyja9lyyIPV7PN71N634/YbD7vou1974sdea+3TERP/eRXz57MBs/q+EQvyOsAz8DnW8+A9HmvvErFz6SQVk/NnSePaacBb4IQUe9FLt8Pz2JKb91dMY+H4GqPpxIDD93WxY9sE4ov3MYCj+hWQY/kYa9PpIC0D1o7ya9tihsP9E5DbwZggk1fLNqspH9fz/BPP4+3IhYPq2V1bwvaVc/9n1VPxsgLrwZOoI8WS8NPynwJb8M4U27vW1TPvWhOz/p1g850Nx2vyqShz5p7AI6cGk8Pydepr72GSQ9orIXP8z1Wz9F4Lk9n4knvlbM8z5nt12/ZvfUPEvlL76l/+8++qyaO7WRdr+Jqok+roPjOjAPtzvunC0+Bg8UP9QGXj+kd8+9RppnvQHb9z7egoS9dvOosWZgUjCtdn8/r/w5PrkpKDnWoBE59b17P9t9gz75XOU5qVceOeBpdz8Byxe+f8qjuWs1I7n2K30/uCFUvVDghj0kJkK9qc9+PyeN/L4i8va+hqrpvnrbDz/l6pU+d+QUP27FD7/drgI/b8umPnyn876ZSj4+/6dLP2bowT2nkGC9A+wQvUtNfj/E/Si/byLDPgc+qj4fLA4/ov8fPkLvHL857Rc/78L+PgAGtz6FOYU+t9XVvZAOZD/NOQ28yo8TNV7EHzKR/X8/QPsWP5g9Vz4ET9S8hIBHP1nSQj9otiO96hVAPa9SJT/VuCW/0x4AuwC7ND4o0T0/A9YPOdDcdr8rkoc+guwCOvozRz/iPZu+gSAZPY19DD+NIUg//jAJPuccOL5d9RQ/NTpWv4sjyDzKmBC+90MHP1ruGDs3uXa/05KIPrHHjzoBack76pkkPnpWLj9kL1w/H7/Nvc+pbb2CV/4+2YKEvTu4T7F7qZgxrXZ/P0wRSD6d+Co5XlgGOfwQez8xaIo+1yHqOXZNEzkDeHY///QlvpqoprlWmxq5l518PzB45bxjQYg9tYlHvQIHfz+xxP6+YO70vso17L6isg4/mJ6XPp+2Ez//5BG/EisBP0Ckwj4KZ+y+sylKPvXXRj/rO9Y9hSsAuzqv3LxogH4/L0oov6Lpvj7i8Kk+I4IQPxRLPz5iiRm/H94aP+mH+j6jjrQ+j7OYPqsY9b3b+2A/wzkNvKrREjW+/VWykf1/P47cMT/vNUY+ooLDvHA5MT9u2yY/+pOHvZETaj0l20A/RUggv0n+KjlEGxs+n89DP4rVDznQ3Ha/KZKHPi/sAjo4H1Y/SgGKvv0fCD0lwfM+IpwrP/WnOT5uFzK+hr4yPxlMS79SHpQ8GYz3vbNnGD+HmHo5Ldt2vxCehz78Owo6yurKO5xKGT4ObUU/0OtYP1uyyr3N7He9a6kEP9uChL3QMjGxd0bIMa12fz+1Nz0+CtEoOccPDzlul3s/QhSFPqxz5jk91hs5hzN3P84KG776eKS5BEwhuXMMfT+Au5081j6NPad3Rb1hC38/4GwBv+c78b61Eu2+lBMOPwdqeD5h6RU/IMkYv/Tj+z6qbsY+xfLWvru5Mz7sPE0/HBvZPYTr0Dv5UtK8p3d+P3J4J7/9DLo+GqOpPn0cEz+jox8+fmMav8LZHT/yf/Y+s322Pp2viT7g/ty9umRjP9I5DbxxwhE1K9y4spH9fz+FcUo/JaUtPqBHq7zUdhY/h2kDP1rSsb2z7VU9FClaPzREFr/o9bc6JXcIPkhuTD/v1g85z9x2vyuShz4o7AI6we1kP12Car6QUOc8U1nEPnNHCD+TDmg+V/kZvis5TT95kD2/+rUAPM7a5715lCk/XL8POc/cdr8tkoc+YOkCOuuYwDuGuQw+/oRWPwPGVD8k0sa9ixaCvY43Cz/hgoS9nhKIMczIBjCtdn8/QEcmPtUxJDkgJiE5N5p8PxKZcz7EdN45EVMtOZ6meD+c+gO+HLKfuaUNL7lk3X0/RuCJPe8MlT08ujy9Lnd+P53hBL9mlOq+46/qvjWpDj/x7S0+QmMYP08fIL8PLvM+SLLEPoM0uL6k/BA+z6FWPxsb2T1s69A77VLSvKd3fj+rkya/vtK0PmRcqT5vzxU/xQfGPWIVHb/Ypx8/PvfyPpzIuT4QylU+vJKrvQ5/Zz/uOQ28LeASNcZDnbGR/X8/dW1eP4CwEz5/rZG8Nk7yPlb2tj61C9G9veQgPZ1zbT/oQAm/rC7rOsaj9j2M4lU/JtcPOc/cdr8skoc+9usCOs0ccT/72jy+YUi6PBlbjz5i8cE+PumIPsPs672B5GA/0lQuv9W0FrtLEeq9sis5PxnADznP3Ha/LZKHPuLqAjooya475bP/PVDKXz+BNFA/WY3CvbdjiL369RE/1YKEvVLjwLFfzUOwrXZ/PwtPBz44qB05YxI4OVjBfT+PE1U+IULTOSzQQzl/ZXo/J77JvfL3mLkI3EC5QcF+P+SD0D38cJ899dkqvfupfT9HOQm//vXhvja95b7uCBA/9imfPZBsGz+pIyW/ezPqPo+yvj5i0o6+sgTNPQYkYT8cG9k9duvQO/ZS0rynd34/ZKglv0CFrz4WIqk+eHIYP9z5ozxlHiG/xfsdP6eX8T4R2Lw+1z0DPtKmUr1FT2s/qzkNvDeuDzXKDMaxkf1/PxP8az8Q2Ps9uGl4vAQOvD6bUF8+s3nkvYh7zTwTHng/keT5vqfRLDuRz+Q9OJldPw/VDznQ3Ha/KZKHPorsAjoH/Hg/7FgTvhdXkTzgHzo+hr11PjOrmT4IP6C9OX5rP8N1IL+mlj688g36ve77RD+tug85z9x2vy2Shz7h6gI62V+ZO+og5z1TDmE/F6ZLP2dLvr35RI6930AYP9iChL16HTExhJpqMK12fz974Mg91foVOeRyUDn+w34/3Z4yPksaxjl/fls5QBN8P7DEg70VBpG58PtTuTV4fz9Todw9kqurPZ5IDL3Jc30/EOENv1tx2L61F9++uccRP1f5yLxiKh8/BMokv6gZ5D5ZxrQ+6s05vgR7aj3agWo/GRvZPTXr0DvtUtK8p3d+P4zEJL/ycqo+s/aoPsPgGj+zeXq9L8clv8SwFz90TPM+CYK+Pm8gHT0ZM3y8D2JtP8Y5Dbz2HhE1fHudMpH9fz9Y+3A/aoPuPZ1Da7wnAaI+gTc+PvRq573AILA8o9B5P5yC9r5mQAA8FVDZPTe3Xj/q1g85z9x2vyuShz487AI6B9V7P60mBr7XUoQ8z8L5PbDVQD6QZ6M+fNiEvZ8xbT+Vcxu/Efu+vKMUCb7LZkg/DckPOc/cdr8skoc+3eoCOq3cgztoaNE9GtBgP6aDRz9jbrq9ukuTveihHT/YgoS9IcMOMcC5byytdn8/9cGDPQUfDjk262Y5PHh/P5VhED6firg5IENxOUpxfT8P//m8gciIuYHnZbl54X8/02ChPb2Ltz3TX8C8eBl+P5FNEr86Gs++d8LXvmSMEz+SLve95zcjPxpxHr+BmuI+cDmoPis9oL1WkZ88m+dwPx4b2T2S69A77FLSvKd3fj9G9yO/o+2lPhTaqD78+Bw/qUIJvuI8Kr92iA0/8sH3PkFovj7o2ke9wmOgPOxBbT/nOQ283GgWNeifgDOR/X8/uYxzP/uG6j0rVWe8ST+SPlP+PT6ugOa9JTWvPObWeT8MZ/m+OEVePCqWzz1aCV4/pdUPOc/cdr8rkoc+EuwCOrUifT+HGgG+orB+PKYpoD3mbCc+6uOqPlpFcb3aLm0/DRsZvxAoDb1yqBS+M5VJP+O/DznP3Ha/LZKHPqTqAjopr2I7YR3APSaoYD8WLkQ/yFC3vdUnl71fwyE/24KEvbppfDHOEzywrXZ/P96VDz2mCgc5QxV5ObjXfz9DNOU9pFCsOZptgTlHZH4/dtydutdTgbkRpXS58/9/P4BnIT0orb89irxKvCyofj86ABa/zQnHvqfo0L4jERU/Aq1Ivl3iJj/NgRS/QgnlPkOEmz6Em3Q8YvYMvHbdcz8bG9k9fOvQO+VS0rynd34/ilAjv31Joj7Pyag+npwePwAZQr7nzS2/CwsCP0Z5/T73Ar0+JDb6vY7NSD24hGs/2TkNvImCDzX6N3kxkf1/P9dtdT/ENec9eA9kvKJ0hT6dhTw+de7lvUldrTwo63k/yGr7volQkzzCgcc9LZBdP9nWDznP3Ha/K5KHPpnsAjoV4X0/QHf2vcYbczxqoS09hmcPPg5IsT49e1a9NBhtP6DFFr/o7S+9ZDgevsjGSj8lxg85z9x2vyyShz5x6QI6KwlJO3C4tD13kmA/AftBP6JCtb1BnZm99GQkP92ChL1KBEAxcjyPsK12fz/ELGw8cd8BOSGIgjkx+X8/ZiO7PXF7ozmDO4c50+1+P2VDnzxxyHe5gI1+uZzzfz+crZU7fKrDPUi9brsX034/kIcYv8pdwb5o08u+cR8WP2JNeL4PdSk/QmALv7a76D55v5E+c6+mPUuAz7zAb3Q/HRvZPZXr0DvnUtK8p3d+P6bgIr+r258+UsKoPpuuHz+LCGW+cBMwvzFn8T6DLAE/clu7Pk1oML6/ko09/3RpP+A5DbxV+BY1l8RJs5H9fz+qk3Y/fPTkPR3WYbyL8Hk+dvs6PsKi5b1SrKs8Cv95P5Ce/L7woKo8VfzBPQpIXT8A1Q85z9x2vyuShz796wI6ojl+PwMW7L2q3mg8Oz2UPGWo+T0uyrU+D48/vXb5bD+p6BS//L1FvZHAJL5Pv0s/jsYPOc/cdr8tkoc+huoCOk17PztzmrA9kItgPzUxQT8QhrS9rHqavetRJT/fgoS9jTiOrnNaX7Ctdn8/khfXO42u/zhLwIQ5lv5/P9Qeqz26G6A5rlWJOdQafz94kN88sKRzuXwhgbmX538/P6ZEvJq3xD3PeQc4O8x+Pwl5Gb8ZNr++MNXJvjSGFj8YT4S+/GkqP96GB7/Mh+o+vOONPmI72j2HeP2821N0PyMb2T3n69A731LSvKd3fj+otyK/kPiePkDAqD6BESA/hBZxvjXgML8q3Ok+4SwCPzKYuj6BdUO+ydycPbuBaD+uOQ28w4cENSatWDKR/X8/h/h2P9Qg5D1RBWG8KtVzPvpUOj6Ci+W9kPyqPEMHej/ACP2+pvmyPGjuvz04L10/4tYPOc/cdr8skoc+EuwCOkBSfj+5pee95n1kPCoEFjzZy+o9gH+3PprmNb2S6Ww/2yYUv0ZeTb2rLCe+YiVMP5+6DznP3Ha/LZKHPnvpAjpH5ok9muzHvO5XQT+vnS0/9owxvHnfKzsnHDw/3YKEvSW6ALGBJekwrXZ/P3ClUD62d+U6rYOcPNiUej+gc+49i5KLO7tRnTyCNX4/9kiDPUKE1rtiEZe8omx/P7Ci5Dw717E9uPrVOdDufj/f1Am/VKLuvpn6y76Z/BM/+ieLPkOACj+NRSq/6sjfPoZBQT+nRnG+HmLMPu2K7T68F9A9fVtiPC0ker2QK34/+7wgv1IIoT7oyKY+Rw4iP/r8ND5wCBC/jzovP8Nv2z5S0lo/B2b1PVmGaL7P7+Y+IwXvPe4mPzvJaTc9q/19P8xjcz9cjbY9zhA0vKDnlz72/Q0/L+y3vUNBdz0WNFM/CSctv/Y+Ij7DrYQ9Q2U3P+DYDznP3Ha/LJKHPiTsAjp+HHy/U24iPu43oLzh/Io99f67Pjqooj2gAQG9nBxtPy0mOL9EFI0+zk3cvRboID/Ctw85z9x2vyyShz4V7AI6fXVAPSB6Rr0ZAzg/NlIsPzoy671ND/29vVM4P9uChL1SL88yZzhdMa12fz/mTCo+NlMCPXfTgz3Gw3s/UF6hPYQHNr2B/H49qXN+P2P+Fz13LS08fCpUvLPJfz+4gOU8yW/UPRbPzLwCcH4/+wMJv/Oo+74+Is++jCMOP9eQqT5FNA0/Z1AYv6un9j5vOzw/X6rBvohbrT5t6eU+uPDmPU3az7whMAK+VjF8P7KCKL/ippY+GO+WPoaIID8/g+I9eGIbv6CyIT9JXfA+pVZSPymEKD6Z3Uq++S0CP/D1ND40TGA9nHLXPZEiej/qDHA/P7kpPnRpp7waAJw+N1kcP9rMjL0Fslk9MnxJP1ZBNb8YNQs+k1L5PY2kLj945N45lhl2v/EBjT7WshU6p1F4PzcFdL43svA8z1ocPaae9T6WlLk9/1VOvacLXz8XJzm/cpwVPhvWNb5GsyY/CLNrOxucdb9lX5A+juuxOj2jhDzOLLi9KGIoP9KqID+8942+j2+lvkDbJj/ZgoS9H5kWM3YEjbGtdn8/RgXFPfQCnT0BNg8+MYV7P3XrbTvFcAu+IxruPXrcez9+bYI8wqYQPQHk7TsVzX8/5YFGPXJDDD554GG9v+N8P23eB78eswe/mrfUvku3Az+OycQ+yEYTP3zc7L4E6Q0/li48Pxa6Cb9gYzk+7869PlzP9z19iru9ILRsvsAEdj88EDS/O/aGPo63dj51Vh0/eHyxvUFxML8gcfI+baAKPxGxPD8biVk+QzLQvYQpIj8E0oE+xOsvPogdOj7bNm8/kAdtP+vMkj4DzRC9W0V5PsxYKD+oWDC97lIaPdNNQD9DV0C/WWXoPRp0ZD5MURw/F8eROtUvdL9gvJk+EaI7Or0VaT/A07O+n2AxPW0XWz6KJxw/oa3jPQ/7sr1Umkc/qSUrv+czub1eD2e+CewzP1QUQzzwQXK/qWClPntMPTtJago7DU/2vSJ8ID+fzRc/K/qtvuoz075yLxo/3IKEvbF6kjKALlqyrXZ/PypufT0LvcA9L0k4PgUqej9iIvW81HM4vvmM+z1muXk/PNqoPHkuPD09mkQ8I6h/P/lDQT2MSR0+htWGvVkcfD/Q+wi/osIIv/Kf1r66pwA/Wku+PsKgFz8CNta+h2QUPwtoQT+DXBW/QiypPVWdkj6lifY94zz4vanWjL4uNXI/Ba84v+s5gD5mIF0+vcIbP1yNp77Syza/VLKKPvB0Dj82nh4/ujp2PpbjEL0YED8/AK+DPrI4jD60xD4++mZoP7esZD+WSMo+OodHvUjeVT7uEyg/VydJveKbLz10X0A/Z5Q0v/NECD5caJw+bCggP5lmAjvFknG/SnKpPuXnXjqg/l4/nO7EvtQ/Qj1KfJo+X+EoP+o46j1NttG9b1Y8P0UKGr8dNle+g/dKvjGgPj8D1rk8gjJtv688wD7V8Xg70qtBu2+SCb6CJiA/pW4WP0U7pb5+P9O+398dP9+ChL0Mpt4x1CrIMa12fz8Wqqc9Y9W4PQeWJD4fvXo/af6GOzpMI762fZ49qPF7PxPtNT1rAGU9B5kJvaIzfz/Rml+9roQgPpNOdr2U+ns/2/kPvyGF7779mMy+VGsNP2LQqD4NMhk/sY/uvhTtDz8WiUI//M8av0cSuT1u6mE+AzT3PSyT7b1z8oi+y+tyP6DjN7/2t30+ZpxhPpOTHD/w/aW+y7U3v5w2bT5FORI/kUcAPxI+xT5Ce+q9pTNEP3oZSz4V4ag+55UZPngjaT/hvVE/808APwkhfb1c/4o+kqAmP7HCnr2mH4k9R5JAP753BL+hqRU+JPayPgJsRD/h3zk71Oduv5Lztz6DBHQ6K9NiP378sL5Lky49lqucPt03Kz9cYlI9aAdAvV17PT8QExe/i11DviX8M769tUM/Tv0IPQcmZ78gYts+YzRjO27oBrxjkim+URQgP833FD9HrJm+nL3Kvj3RJD/ZgoS96uqcMfqPwjGtdn8/BwYCPke1wT3s0NA9Y2t7P0sVkD2R7qK97Ea4u1OMfj+DK2499aodPfyJgr3f2n4/5Q4svnqSwz0OfAC9igt7P9PSF78NRsK+6/+8vj1OGz/mZZk+mlcYP3hSBL+nmwk/YndBP9XIHr/qcvA9PHoyPs0S+D0Xmta9In2AvmBkdD83Iza/VJd6PupLaz5xCh4/tIk6vQAvOL9nb5A+gg0iPytC0D6b9vk+RTAsvoXsQD/GzPY9dyy7Pi638D3dWWo/1sNCP/XmDj+l9Iy908ilPrY+Jj821+S99aXHPUnwPj8w96W+l07GPeLhoT6T5mI/gdZeO20Qbb9XPsE+96R7OtNUaT/Dq6G+8ncfPU6MhT4dsyQ/PsXPvCcvpDxZz0M/eKcYvwLPKb6zeDu+84hDP6ttKT2JPmG/lGTyPqceDTswonI6nOx6vluhFD9XJjA/EWx7vidhnr571hs/24KEvaLUULKkDJ8xrXZ/P00cLT6AU+89fACRPKB+ej8AeQo+vyeUPcLD7b05OHs/PnJzPMh0FbugVcM89uV/P2aHKL7svQy9EPsyPZwbfD8XoRq/VbGwvrOjtr4HoR8/Is4HPi5+Gz8JsR6/diH1Pt1fQz/NHhG/lloRvZ/DnT6h+/c9gX+2vUT6aL4XTHY/GJwzv+Bpez560Hg+C40fP2l/JL3hbTi/p86GPvvtIz/E2J0+x9sMP79qLL6H7UE/E7JSPaRexz4YHrs98UJqP0z4Kz+HQgI/SHyAvd/hCD/c9jo/2lWfvbNYmD0KsCw/V0G8vtidHjygx4U+q3ZkP7tTNDtIO2+/1T+2PhOgbDq31W4/yVagvpwnHj0ufzE+0JwSP+ynOb1W3gU9615RP1uqJb9i8Km9aztrvsfhOD/LsTQ983pcv1GaAT8jjik6r3GfPHgIqL5KEPs+5NdgP0Zh4L2QMxO+3qHiPuKChL0Ahxeu9hEiMq12fz94fT4+fBQJPpbRZ72xw3g/HrslPk92UT57XVe+pzNxPxkHnL24Egy9MPQpPuuKez8JMrC99cgQvjwA0D2AIHs/F6Eav1axsL6zo7a+B6EfP+LNQr6ilTI/MjjivgbvBz/XdyI/LyiJvmoM0b7lVRk/oub1PQqEkL3tAEy+alJ4P/yBML9v+4A+rlWEPpTCID86xGM+/cYrv+d4Az6/DzI/TKEJPs7L2z7gRcG9NVtjP0E5djz9v80+ltyLPUu8aT9bo9U+Ws+IPkLyBr2gNF4/zeVUPzNooTyFfxG9esgNPztSD7+6fxS9fv5FPigOTj/Z5Ww62s50v4G7lT7e8So6Nbx3P+QBaL7J2OQ8BMnaPQ2B9D4WPNK7OfyrO8XpYD8uGDu/PcDaPRp7cr5VlSE/jhYsvX/BWD+gyAe/5q8KOjj6uzzTKLS+hCHrPpmbbT932Am9VOiKvemTuj7ggoS916w9MngjgzKtdn8/QKVLPvWh/z0Rrpm9xhl4P1ybJD6W4XQ+FcZuvlzDbT/cnRK+9sRnvbGLUT64dnc/oSCavD8xM75fid09S3p6PxehGr9WsbC+s6O2vgihHz9O4o6++o85PwVOIb7hHRw/E6cAP78YOLxNPgC/Qlw0Px5J8T286k+9LlAsvhA0ej9ODy2/rXyGPoqsjD7LmyE/F3sQPzuu/74cbAi9VxAoP37wiz3CxGY+Oa4vvdiOeD9LQ5E8GjjGPlSuQj3ZrWs/O5aYPmI6FT70MZO8c3VxPyd4WT83xiE9vg+EvSysBT8Kah+/ylmQvML7Gj4CeUQ/rNYPOc/cdr8skoc+zesCOv/Sez9K5iG+q7GfPAkbqz2KaeQ+7HiBPBAhAbydEWU/fO1Evy3vHj4mA1S+sY4VPzgEFb37xFU/gooMvyrLmzrVG6s8FOiwvl8w8j7WhGo/P+j8vPLlg70MBMo+4IKEveABzLAg0TAxrXZ/P2cHYD60UuU9mjyLvXmJdz81mxw+dxZ6PjadWr6W+G4/LHMzvmGKqr03rDA+gjh3P9vb/TwVEjq+XA3PPUtHej8XoRq/VbGwvrOjtr4JoR8/rPmKvq1gOT9SJdG9Ry8gP6+a+T6N69o9nGrVvoJ8Qj9eSeo9oTMAvQBXDL6bwns/GYcpv9JDjT5juZQ+nBoiP43NFz9xpPO+S+lsvXSgJT/7QwU+nfJdPpksDL4uMXU/RIQhPd8Ipz489Qo9eKBxP0cTsT4S/i4+upusvIAfbD9SnVc/8RaNPBsx37z/wgk/mGAgv9hdzjsl0Q8+wENEP6vNDznP3Ha/LJKHPhnrAjr953s/EW8dvg5KmzxmEbQ9/733Pj2oPDxvyM67qQJgP8U3SL90a9g9r/9QvqxHFD9qiua805JTP1byD7/tlqU6ZnKSPM17q74zFP4+ZYRlP5kaB72m1Ju9VMbePuWChL0ldtSxNDa5Ma12fz/5nHQ++GnYPTWqeb1/nnY/+asQPkO+gj5ceTq+iWBwP07NQL7fpue9yED7PQfEdz+LH5Q9ebo+vj9nwz1PpXk/GaEav1KxsL61o7a+B6EfP3V4ir415zg/j1yOvS76IT8dg+s+k9tWPnecm761tk4/I8rhPaW1YLzAV929A+h8P8w0Jr85UpQ+y92bPktKIj9H8xw/BmHsvkNFcb3OayM/Lul8PuhRQz6TSYe+rJ5pP6lHhj38V2s+T/HxPFZ3eD8uSNU+HAlGPndWw7xxUmM/wdZTPxGXhDuSY8m7e7kPP+vWIb/kI808DIoHPg9VQz+M1g85z9x2vyyShz7l6wI66617P0h8Gb4VZZc8sXjTPc6gBz95qLw75Fhou+ccWT8HeUi/hLRdPeLCV77gJRU/0u6YvLEmUj90HRK/IZtmOu1EaDyUxqW+EK8FP8+wXz+9WhC9uay/vf6p8z7fgoS9rh9Cs+FBSbKtdn8/pSODPp7W0j3Kal698qh1P4RPAz5YTog+HtoWvo6kcT/2l0G+xskNvq6jiz1AQng/C+nWPcmiP761qrg9aPh4PxehGr9VsbC+taO2vgehHz/J+Yu+2oc4P/QiXL2VeCI/bgrZPuqTkD55Fz6+4x1XPwlQ2T049RA6pf+rvSilfT8gaiO/SqSaPimRoT6uQSI/wmcZP0FT974trwk8P2sjP54t2D6OqQI+7lO1viUbUz/6X7k9Bs7+PYOcBz1Lz3w//xn6PuyjWD5dsNW8dZxYP7kiTz8VRl67sjqWO6ttFj+n7iK/hfskPSnnAT6UfkI/TtQPOc/cdr8tkoc+VusCOo6Mez/8KRK+XyyQPMJ48D0e5hA/ejX5Oj/HqbqBC1M/rzdGv25JNjwgFGC+NvwXP+WdHrzsZFE/LUETv2/QmjnOAzE8lVShvkUtCz/Xolo/eZUTvZAb373X4wE/14KEvYZsTTNAk9iyrXZ/PzRViT4E3tA9FTFJvRfpdD/C+O89QfmLPpoB873QhHI/EeI8vgPwHr6mpcM87V94P0fqAT6grD2+q+ivPWJ+eD8XoRq/VrGwvrOjtr4JoR8/FfCNvoZXOD/LiEe9GV0iP4dXyD490aQ+lOW8vSRwWz8ZxNI9c4MmPF8air2mCn4/rHshv2A2nz45W6U+eSEiP1vGBj+7Tgq/6ywZPoOiIz/PtRs/8WWGPencx75NITA/E4DfPalCID3p0CU9AhB+PwMRCz9X12U+87XivE79Tj+y4Eo/cor4uxP9IDwLGRw/XWMjv7WcUj3SN/09QRNCP5DIDznP3Ha/LJKHPmbqAjqQn3s/0zMJvkRVhzzQNAA+lD8WP5oCFzqcE+C5dUVPPzknQ79lZYW85dtlvvpXGz/yKES7nxxRP5esE78F4Fy5NtIXPGp6n75GjQ0/dGJYP6u4E7386ey9EjwFP+GChL0Qo5iyRmLyMq12fz+oxos+BpLQPaFHQL3AmHQ/BQLmPdRKjT5ivNm9dNpyP1WmOb5gWiW+FRGkO1dWeD/nbgo+jRs8vuQfrD1vUng/GaEav1ixsL6yo7a+B6EfP2ftjr4OSzg/ShRGvXY1Ij918sA+IzKrPlEvW72Ctlw/vxfQPYdbYjw4JHq9kCt+P/q8IL9ZCKE+6cimPkgOIj86QfE+IMIRv7lMcT5ujiE/Fr8wP7y4HD04xc6+S1YZPy4F7z3sJT87yWk3Pav9fT+AzxA/yjprPmIG6LzSnko/Pe1IP2UyFbw6xjw8qpYeP7d2I7+PP2U9YvX6PZL5QT8L2Q85z9x2vy2Shz6G6wI6ubV7P3KRBL4zw4I8KWsCPmYAGD/ci/M5Utu5uTb9TT+2kkG/P3HUvOMMaL6mBR0/1bacOWwRUb/xvBM/HsLdObNadTvXAUc890BfPzleQz/1ira99teXvRm/Ij/ZgoS9i92DsW8sTbCtdn8/9fJ7POswAjneRoI5QPh/Px0avT3c5KM5Fu6GOQfofj+TYJc8NV54ubsIfrnP9H8/q+OKunyixD3r4jG789B+Pwl5Gb8XNr++LtXJvjWGFj9Sr5K+IWwsP9Lc/b49TO8+CISPPnWmLz1pP6C7Hn11Px0b2T3m69A7IVPSvKd3fj+otyK/jfiePj/AqD6CESA/rKKWvko/Lr+sS/A+BXz1PssJvD7HYB2+RZp8PUNOaj8dBe89YyY/O7FpNz2r/X0/MMx0Pw1Z7D3cIGm8onaJPlmJaT5y5d+9QxvTPOGWdz+AzwS/+667PP8tvj0Ne1k/VNgPOc/cdr8skoc+K+wCOl7KfT82yAG+oAOAPM0D8zxzbhU+Kmy1PgfFZb06BWw/WBEYv+6pS73tYiq+lhVJPxbDDznP3Ha/LZKHPhntAjpeWqG6mCXRvUmbWT/grEY/SPTBvcfRh70ntR4/3YKEvQvnDjMEdWGyrXZ/P4aoRT1OJg68EdCoOS2xfz/fc7Y9HArNvLZ2Qjwq4n4/WsFZPIz/gjwyxCC8re5/P20Fqbz+yuc9/Gl+u1xMfj/FKRi/ek7Bvio+zb7+BxY/kIc8vtn9LD9OuwS/0Cn7PlImlT6+0Jq7sCIVPA7idD8dG9k94urQOxlT0rynd34/9lUiv7EvoD4cKbE+u90dP+CXkL4o/Cy/AEr7Pr+m8T42La4+0v6LvZ3O1jwuAHA/MGTdPafcLTztBIg9rep9Pxs4cz9EbeI9xldfvCM6lT4wKsE+uLvNvYe+KD1rcms/LdMgv2W+Bjw7+KY9pxFGP3KYxTxgbHW/xBWRPgCn1zvj5nU/Z687vsYguTwa6VQ+jBeyPvXYlT5uFOy9RxpiP++oJb+Ck+y9qXH+vdVHPj+cvQ85z9x2vy2Shz5s7AI6a+RLvIVY8r2CKUs/tx1OP8yf373omzq9D8cUP9eChL0yh3KzgOydrq12fz87b/s9c4bwvJ4HXDnB830/WQalPTGGqr3HHjQ9wAZ+P+0FLjuzolw9qSsLvbp6fz8+IoK9wDIbPhJ2pLsZhHw/XPYUvyVNxr4WP9W+dtEUP9URgT3XfCg/uUsGv7RNCT8CJKQ+cC2MvRv5/TxSuXE/KhvZPSrs0DvtUtK8p3d+P5EGIb/FfqI+swbFPlKlGD8VFnK+k3kqv2sXCT89yuw+72mGPmT6FT4XIBK92PxzP3V0qj1W31I9MQDtPfcKfT9vmXA/8nTDPQ7LQLwq1ac+xvkEP9Six71U3XQ9bslYP7eLN79ZHRK9fESfPaAbMT+WZak9TxVxv+iwpj7wPI88Yv5iP04hS74GXcg8+3bVPhkkBj/vWkE+nZv2vZVeUj9jHDC/agXmvT9nkL2WqzY/6toPOdDcdr8rkoc+LOwCOqNSxbyyzAG+Qwo4P1w8Vj+1lwG+XLeCvB5ICD/ZgoS9AGKXMY4VirGtdn8/FfdPPgc4Wr3Fvmu6I0t6P4RZjz0j4Re+j022PdqAez/Mlte7znDHPQoQhb3xO34/VhjcvSPdQz6PsVW76MJ5P1QAEb/wQcy+PY7evg9NEz9mxKw+9pAWP60K+74KLAw/Mou7Pgcojr37shA9I19tPx8b2T1S69A7/lLSvKd3fj/1vB6/njCkPsBP3D7TgRI/U3cdvo/ZKL8j9hA/g4TwPkBUIz4Owsw+9ep9vd6CZj8JvBc94gIbPv1jLj7cFXk/7cxwP5aLmT0PdBe8pG+pPoAWGz9Vmta9frGlPRHWSD8qNEe/4mubveju1z2IUB0/VcofPsBxar/4Eb0+LUHIPKrjQz+N7CC+XruePCTAHz9GIik/jAmePdlzjL1YWD4/atIyv5efo72WOAe9SNk1P1XPDznP3Ha/LJKHPmTrAjolj/u8HwP/vVt7JT/fjlw/zYkLvuaYtjwEIPo+3YKEvawiWrP6hc+xrXZ/P5dUhj4+XJS9phpKu21Vdj9j+Ho9rrtLvkzhBT7nJHg/sBE3vD9wBz46Nb29T6F8PxpCDb516Vo+DHTYOkqTdz9ZkQ2/nj3RvuQk5r6d+BE/ChAGP7Tg/D5cEfO+P6MBP45c2T7Dshq80ThNPCvAZz8bG9k9vevQO+xS0rynd34/Xjscv1PApD4PY+8+u3kNP0bje73o9Ci/uaIPP+za/T6WWqI9hWoWPwcnN73M1U0/iwoevT5vqj47alA+w4BrPxk0dT/TD2Q9KPTgu4FKkD5onh8/AKr5vYo8yz20DkQ/IYNPv4stmb3JCyM+0P0OPyMSYj5u52O/O4nLPuof1jyyFh8/8uGaveDFGDyGnUc/CGo7P6gtsLybbL084jMuP+FeKb/XMGK9dGX0vPBJPz81yA85z9x2vyyShz427AI6UuPmvGSP5b3/axk/TEBfP9NsA74o4pk9Q7XuPumChL0UjGQymtjXsq12fz8N65E+4TukvZUckbs7hXQ/sy1sPTVrYL7YhRg+M2h2P3HXR7ya8RU+C2LVvQrQez/VTRi+5StQPjlKAzyjvHc/9BgMv+dT076AROm+vWURP7YYFT+0BOY+HlL3vpc08z6Gpfk+3o0LPcdTLrzSUV8/HRvZPU3r0DsUU9K8p3d+P3QGG7/xwqQ+gED3PjBnCz9IuDA8IqApv+7eCD/tPgY/kCNNPeHfJz9gwOa8K7ZAP7diCb6itRk/YY0zPr3CRD9etns/ZxAjPf3XoLtSDTY+eG0PP3vIG773L9g9na5OP79lT79w0ly88P5bPiyXCz/bvH4+yPRgv+kj0D6aRdU89n8DPyCE/bzHD3o75X9bP4ZKOT/7uLq9cprHPQlPLT+YIBO/nEWGveHbhL3cKVA/XdIPOc/cdr8tkoc+D+wCOkxzvLxPpZW9vYMWP1lfWD/5WiC8tDNPPuk2/T7ggoS9uPxBsaJkfbKtdn8/q15lPj0yeb1QXIK9jnl4P+VsOzyNfzW+a2RuPR19ez9jTx09Sbj3PadugzuU7X0/cN/JvfeMnT0MoCA8gfp9P51FEb8YG8q+mDblvos1ET9u3eQ+DcMOPwd70b4WORE/mx0OP+fAHDuCgew7x+tUP02itD3NAPS8tVRAvN3efj/bvBu/8Z+lPt8L9T6mUws/uUaZPQUeKb/AkgI/xbULP/rcBD510yI/+4aQvUzkQT9WHwy+nAtOP1Sesz3aHRI/K+x7P6jFCD646Ia89d7tPRXmAj+Hfyq+qk3QPStCVj/M/ju/RRMuPQPOpz6Fxhc/9HRTPixiZb/gzMg+NDzVPAXwGD8wlgu+aa+JPAFDSj+8MkU/GuwEvuYeKj5zEBo/vF8tv/FNrT2XCAC+t1g4P5PFDznP3Ha/LJKHPpjqAjrjcLW8R4BFvRR3FT+j7j0/EGpHPuHZzj7BLv8+1YKEvfsS4zJTIM+yrXZ/P2pU6T1St8y7X7O6vUxBfT/mBVu9M0+jvIRIDL2wbn8/WIKgPXu5gDz5+As+KcV8P52LLLwqzDK+Y49ovS+iez+TWRy/1ke2viMR277tLBA/criFPtbXJT/kRbO+ncUfP0RjIj9UQUE9RhXwvKJkRT/c21I9+fHhvV8dajzFEX4/wyYdv5Z0pz43nPA+BSALP91rgz6ujhu/ANEGP4dGCT+TBmQ+aJoTPyrRz726j0c/CKl5vGIkTz9I9YA9bIIVP5HncT/Umok+C7sHvZ4lPD55a/s+i2sovsWIwj3ZpFk/C7wUv+Pmsj2q8M8+Ji0zP7ry8T1OAm6/PT2yPqdssTzIOkA/BTO8vrGiOT3m+gs/dNtKPwrUc707caA9qBwaP078Pr+IQm8++ws1vvYUGT+w1g85z9x2vy2Shz4y7QI6R0K4vI9e/7wslhM/dgQTPzxNyD7M3w0/j6LqPuGChL1wIVuykLOkMa12fz8q9os9LUw+PaQe9bxnAn8/erocvf+lDz6n0tG8wDF9P0CKmjsYzq29yXQhPhLcez9aVBo9C369vqZoDb5J+2o/+fEmv1w5o76fVc++h1QOPyGQkD5B7B4/3JvmvhWDEz+JDTU/dhcTPvRVDr7smS0/3kGaPHfTQ759jAk99xR7P05gHr/RMqk+LLfsPgrhCj8khS4/wKTCvnC04T7b5+I+vjYzPiE0Qj+CuzS+mC4aP8jG2r0FTRg/mKODPRdHSz9R0WY/7m+JPpOQB712zaw+Wxz1Prp/M70c+8M88mRgP69dA7/JALg98YjKPsyiQT+EOhM9vaJ0v5unlT7fERc8YqZYP/zR/L5LYHk94P1CPt9iQT9VWwM++yofvqWcHz97vEe/qZhsPnvvS75FzAs/h+EPOc/cdr8skoc+0esCOuZDoLzWs5C8k7QSP0nx6j4W6/Y+soQeP7g51T7dgoS9xh4as10sCDKtdn8/+LtxPfJLlz2VpqM7jtl+P4WUA7zswmA+tBMivGK8eT9dIGu9NwUFvup7Fz4qj3o/mySMPdga876ctBu+qDhdP9CgK78J/pq+5GHJvloxDT/IZYw+TZEYP2vKCr80awY/NYw6PxBXSD7Kxl++LGweP+VqtDvXW2m+jQ0kPYYMeT/PLh+/6BiqPuLs6T5D3Qo/SvQ/P+sKpb7T684+K27TPqYhMz7m4Sg/lM0lvlh1Nj9HhgW+YgaZPq57xz0iuHA/Zd1jPwFAUz5QX9C8Y6zPPvF54D4xDpk9WwMWvWYYZT9Ngvq+H1aQPTyOyz6K5UU/ycEPOc/cdr8skoc+rvMCOrM5Xj+0ifq+FCB3PZ7cbb03yC0/BbOQPqmqpL6atxg/vq9Kv0pzGD7VY16+zRoNP364DznP3Ha/LJKHPofpAjpZXLq8Rv+EO+7REj95ndo+L4gDP8DoJD+ltL4+2YKEvSCLAbNqRp2xrXZ/P5NbdD2cXZo95koPO1vQfj+QMsW6UW1lPrwoR7zheHk/XLiAva9lB74mHRk+/FR6P1/irz3IWAS/yG8HvnRiVz/TnCu/ciibvmxRyb5tMA0/nL+LPk0RGT9suQm/Tx0HP6anOj9LM0U+mYhbvqzpHj8ACLo7zdtovgO9Iz0oFHk/nXsfv7oBqj6Gneg+AxkLP88zQT8OYKG+Tq7QPr/0zz568zg+xsQiP5g6IL7v4Ts/RwQAvr3okT4DMMI9IRNyP/rTYT9lgjc+dwK1vCa43j78I9E+IaWFPXQO8Lwz82g/6dbjvqV56D0JqNA+IxBKPxe/DznP3Ha/LJKHPpHzAjq4+V+/wWHwPnsbbb1XftQ9ligoPweToj4eRLe+7S0VPzI3S7+khzA+gRxeviqYCj8wug85z9x2vyyShz7e6QI6f8TRvEZJ+zyavRI/NSXQPgi+CD/FhCk/5YaqPtuChL1k56wyK70eM612fz8N5HI9ZimqPZL7VjtRqX4/x7KKu0RyfD4rxlO8/hJ4P3p1gL1FPxe+sgsYPpvOeT+QT5o9AbUCv6a9Db5xY1g/0p4rvzwTm76pWcm+5DANPyrhiz718Bg/NwMKv+ztBj9wnjo/SpRGPpZtXb7srh4/IDm3O84bab5a5SM9WBB5P8JxH79Vyqk+UPPoPlcRCz/+dz8/isycvlzu4z7iZMU+PO88Pif6HT8fgxu+zO0/P0EEAL7A6JE+FzDCPSATcj8dSF8/xh8OPkowjLw7/+8+Y8TVPnwhZz09+9S8RRNoP8Td2r7+/xo+6WTOPhN+Sz8fvg85z9x2vyyShz6B8wI6Vqlhv70S6z723me94/7BPcDpKD8e+J4+1vWxvvTkFj+ylEi/F511PujVXL6U9Qc/CMsPOc/cdr8skoc+h+sCOmLT6bwMr/g8RZsSP/i+yj4rUAw/KKwrP281nD7dgoS9En0aMpBetLGtdn8/8K9xPUF2tj0qVpg7CIh+Pzr247t3IYc+EqRXvLzkdj8mYH69bJ8jvvbYFj7yX3k/PC6EPd1IAL91fxS+gsdZP9CgK78G/pq+6GHJvlkxDT/GZYw+TJEYP2zKCr82awY/NYw6PxxXSD7Yxl++KmweP/JqtDvYW2m+lA0kPYYMeT/MLh+/6xiqPt/s6T5F3Qo/bGk3P0zEnL5LiAM/4dy3PlioSj7iUgs/ZyYJvqveTT9KBAC+vuiRPg0wwj0gE3I/LyBdP7Jm4z3KTWC8YYz7PuuI2D5gm0w952y/vH+MZz+uX9W+vFgxPvNuzD6zTUw/Tb8POc/cdr8skoc+X/MCOmDVY7+E/+Q+8OBhvX7Jjj0uQSs/YqCWPguBqL66Fxk/KhlGv6G2mj42n1i+m9EDPyy3DznP3Ha/LJKHPrnqAjok0ha98twIPZ+IEj/Kjcg+9usNP+/oKz/WIJg+3YKEvV0iyjOZV24zrXZ/PxtdmT1fiag9KyMzu9Rofj/F7Q08AXZ6PmvHnbxdKng/NO6FvZVWFL59DBM+2g56P5HBcz0OAPu+h60CvjYyXD/SoCu/B/6avuVhyb5XMQ0/ra2UPg4PFz8nqAq/yQgGPzB/Oz/NzDw+XhRSvntbHz96qFA7lHFWvoThAD1MMXo/8Iscv66qsD6tJu0+LnEKP3g9Lj+IOai+01gLPwRguj5Kj2g+4iTrPt9R+70yl1k/Q+3svSnChz4ju7A9UA50PzSsWz+DVL89Tbk8vLw5AT9YPtw+M4ZpPfgu37yZiWY/rl3VvneLMT7BAck+nyRNPxe/DznP3Ha/LJKHPpHzAjp6OmS/OcTkPlWmYb0JwE09JUEtPzCYkD6V36K+fNEZP90IRL8yM6g+GKZUvk4tAz/jwQ85z9x2vy2Shz5r6gI67dtovTCiHD2GMRI/1XnOPgYTDz8Y1yg/oqGZPteChL3GB40x3d8Usq12fz8xw+M9P3+FPWiBiLwJ1H0/O7VQPZXnRz6s7O68y596PyOZm73DXd69TwIEPj6Wez9AVC49osDsvisDtb3rl2E/0aArvwj+mr7mYcm+WDENP5OLqD7u1xM/83AIvwsEBj9fpT0/qOAePninLr4wgyE/tWWcunUaJb5RKB08cqN8P7OcFr8qfb8+BMbyPvCoCT/wIyg//6K2vtU7Cj/nKcY+tkyQPsuJvD7yD/K96MhgP3zAvb0CpFs+ZeOGPa5XeD8sJFk/+3maPUNfGLzOMAY/bVPiPoqSpj3pECW9o3NkPzlM3L4FaxE+v8/CPuVhTj9Vvw85z9x2vy2Shz5Z8wI6oEthv9wl8T7o3G29OxuLPEVBMD9Pf4s++vahvh/QFz//q0K/Uf6jPj3IUL7I3wY/YbkPOdDcdr8qkoc+qekCOsK/tL3NxCU9sjwRP95C4D4BmA4/Sy8hP+kVoz7fgoS90ngNszhWV7Ktdn8/sqYXPkN6ST03dLO8MM18P2y8vT2Rthc+UUf/vGXvez8l7ra9uWOevdhB2z2iuXw/VPikPHRt4L5i8Wm9qJJlP9CgK78L/pq+5GHJvlkxDT9zj7s+4nYQP0YXBr/OwQU/JwY/PxqIAj7f1Qy+C4cjPyOju7q0GOe9K+U6vBNZfj/8NBG/YBPNPnXy9j4/twg/Qw0qPzH6vL6i7AA/rGrSPu+mqD6NFKI++Tbwvf+7YT86yJK9/FUpPq1qRT1ggXs/3wlVP1vciz2C9Am8BtsMPykz7j7oQd89Yw9uve1jYD+UXem+48utPS8cuj53204/DL4POc/cdr8ukoc+SfMCOi2hWT/WbAW/j5uDPY5dID3COjQ/z++GPtwtpb4JPhM/JaJBvwcGiz4iRUm+vswPP7y5DznP3Ha/LJKHPpPqAjqsJvS9nLkQPdCNDz98Jfs+MMkMP0hWFT+F364+34KEvagwAbNypx2zrXZ/P+QHXD5/Ta48yWKKvG7seT/dVC0+XkqEPcZGqrwJtXs/lwHzvYSo8LxAVl09DrR9P686/Lxrk86+TOIGvKEYaj/QoCu/CP6avuVhyb5aMQ0/+ADiPl5nBz9hJgS/qkMCP/cxPz/OU6A98XygvanbJz+uHy88V/eFvMs+Tb0moX8/PXIHv89L5T7nGf0+pkcGP003NT8DiL2+C4zLPioo5z7/FdM+/NZxPuIm4r02el8/ACoSvbULmT0heaE8HhJ/P9G5UD95AYI98DsAvGRQEz97wvk+PKcjPrPzu70gcFo/Yar8vgyRYrwyKbM+kM9LP9K+DznP3Ha/LJKHPnTzAjon2E8/Fw8Rv0kVjz0+xPk9Sqg4P0PjgT7maam+TZQNP2oZQb/vuVk+0c45vkcUGD9euA85z9x2vy2Shz6D6gI6HEIPvjVUuTzm/ww/0swNP0twCT9eZgY/eSG4PtmChL3IFM6vYGZXsa12fz8GU4U+H0A+O/nlS7t4Knc/t4ZjPuT/EDwhD267sZZ5P7SzEb6Fq2a7kHYGPI9ifT/rzpe9FDzJvs9i5TyxhWo/0qArvwX+mr7lYcm+WDENP093BT8vX+8+WJILv6jy6z6mxzo//sJCPUh0Jb3ZVi4/ACM4PfA4mT2Mb6S9fTF+P2OoAL+n3/U+ZjAAP+EMBD/PuEk/U6WkviTFez5iiO0+5Z3vPqVFPD5Uv8y9gcxbP+F/SbxniC08C5MoOyb3fz9W10w/1n2fPbJRHby5ORg/0M8BP8tbTz5fTP69CBpUP56NB7/Kc/K9iVCxPkXqQz+cwQ85z9x2vyyShz5u7QI6RMBFP7m7Fr8arpQ9SQVoPvYlPj/ggnM+oqWqvlOfBz/QHkK/l1cqPoOQJ74L1hs/BbwPOc/cdr8skoc+KuoCOo+rC760NAs8tUcDP5uqJT89vPo+QRrcPiabyj7VgoS9JRagsAZvMDKtdn8/WBOJPgxUurNKgrszn6d2Pw1ObD6BJr2zxfN+syEXeT+e6RW+wFmlM04hGjPkPX0/M1ievfalyr6svo49S5RpP9CgK78I/pq+5WHJvlkxDT/9yhQ/By29PoO6Ib+bI7Y+H8oqP0nTYz2i9SO9fOQ9P/k25T0DRAU+AXNVPK4tfD8BGP++l5L4PgNrAD9DpAM/2dZeP7WhZb6lbNw9kHnZPrw59T4s2SA+4FKzvej1Wz9hbzm9wzwJNbhmVDPOvH8/NxxCP0cPfj5Amfq8AyYaP0iwEz+71bI95wx7vc9PTz/U2w2/MIjJvdIqwz5Swzs/d78POc/cdr8skoc+3fICOgEbOj/4HwS/O1OCPSKY5T4BBVI/NsMTPkOGcL5dPwA/6jJHv3tfPD4z/iK+nT8UP1/BDznP3Ha/LJKHPqbpAjr9QNW9Z3eBOySD9j7Ta1A/jz6TPtBCYT79a+g+24KEvRzSNrOwO/oxrXZ/Py8Ghz7/iyM6xutmO4/vdj9A62U+AXEnvKIbXDokc3k/PwMQvkLH9TtoENu6snJ9P1jPXL2w3a2+ez8MPjHSbT97eyu/OHGavpLnxr7FZA4/n2kZP9+IqT67NCi/A4ShPgDNBz8AAng9+QT/vJJPWD/RGR8+WisePswl+D3c2Hc/HWr/vjY++D55PwA/r84DPwtcaD/WjBa+hQXOvETeyD5y2+w+HigqPvH4qb007F0/oNwsvkaoEjV0B8Izd1N8P3IHVj9sqdk+WLJWvYmJrz7jlRM/bE6DvQhrND3NOVA/n9cgv7xUYL56FtY+ZE8eP74RFjlKB3a/eoGNPkV6AjpdIBw/nUibvicrGT0EMTs/38hgP3IbRD0suLe9BGvvPmclS79MxJs9phr7vahWFz8Gxg85z9x2vy2Shz4B6wI6hH+KvfBXbjxCRQM/Po1oP/t5dD3q/1q8a8LTPuaChL2umZWy4GXWMK12fz81emU+tASjO4s9Dj3KU3k/MQQmPu1f8b1AmBM73816P68RrL3GPbI9zWFKvK8Zfj/OdPW904nKvVMW3j28XHs/5mQpv7zBk75l2a2+wVwaP2j0+j5CYgc/zi7bvsd4Cz/gDr8+b9oNvWdKljzbS20/cYwsPjVn0T2pxxg95Mt6P/t5Ab+0jPQ+D6/8PqyiBT8mkRk/BSXhvvMoNr7a8SQ/0JODPr9m4D6Z8QC+siBaP4ado74M+QY1GdErNKmTcj9DtnY/PwiFPlM4A71VM1U93a/JPqFUBb7ZFV49pINoPyYlOr/laY2+uw2rPi5HCD9wi1Q5opNrv0llyD5M3fk5dwQCP4IBMr7NlK88PutXPyE8WD8GVK49EL0MvrmiAj9Cej+/Xb6WvbPcVr34VSg/tMQPOdDcdr8rkoc+0+oCOnV+SL2ZawI9YGcMP8YpbT+jYQO9nRcTvuVssT7ZgoS9lINeMrYWiTKtdn8/EkM8Pq7mLroPqH495yF7P8/awz2JVoe+IPjmu82rdT9Bs9e8MDJIPmROarxX8Xo/TwxovqZ+NT5IRwI+FQFzP/G5Jb8V14m+Hu+RvmhSJz9DNkM+1FouPyAXPL5jxC4/49WJPr0rBb5McTM9egh0P8SQMT6pRyc9j5ZtvYZ3ez9bWwS/SE3uPkI89j6WnAg/rTxaPmttLL/v0v09tWIyPwKdaT34dgA/uRcJvRPJXD/iANS+d7YDNRhiPjTXBWk/UZ99v/EABL6XNII86M0kPbGWbD435yu+EislPeMedT+DaUK/okYLvlvZMz40ixw/Z4uLOfeaW7/FkAM/4u7oOfLq+D7m1PC9LY1tPM6kXT+9d0o/0ZwUPi/HUb7n3g4/gd02v0vWwr0oDR28bHkxPxzEDznP3Ha/LJKHPjTqAjoSHCi9S6QtPYxeDj+eSm0/kYt4vXBsLr5CW6g+3YKEvQS0rDOA34QvrXZ/P9jtNT6WU5q88HiXPSIrez9dM6Y947OvvlO2TjoHjm8/99yBvBCXgD4VKrq8arF3P8L7er5dC4s+CiYLPryzaz+iuyS/SFWHvunwi75iEio/iBq9Pb0oND8wPRy+SQ0wP3Phfz7Kiha+qdE8PXK4dD+g0S0+93rPPPdSoL10Z3s/4ZoGvzc26T75+/A+sO4KP52ryT2CjDO/tCF2Pj/uKT9RWXQ8jMT/PsjuDLzIuV0/4sbcvpEp27aMCVs3IPpmP/KOfr+NKrW9ELMyPMvTaj31TDU+++E0viFFBD33uXc/CTM/v7B0xL2zPRw+ItwjPxZzkjnPjFe/+BsKP0yb5DmLyvY+nMfdvdXBWjxEjV4/1qZGP+G5JD63oWC+JK8RP3bvM7/3F+K9dUgLu7fjMz94tw85z9x2vy2Shz5j6gI6UMoTvbD0Pz3BAw4/GBdtP1fNo71ikS2+qZinPt+ChL0Pukcz0ItfMq12fz/XuDU+7XnnvHtmnz0WC3s/ZKmkPWD6u76gCgI81jhtPzWzgrxIz4g+YizqvJ6Mdj+YWHa+sbiUPqfKBD4kwmo/hLQkv1GIh76oJoy+DgQqP2Bxoj2p2zQ/D6ktvt+5Lj/IBoA+s3gTvuafOT3q1XQ/S84qPn86yDx/Mp+90ox7P9vJB79Td+Y+OC3uPqIhDD/IT6s9cxk0v8QNgj7gjyg/QbN5PMqY/j5iIw+8gQ9eP5fp2766R6K46EIXOeAuZz+Vk36/UJ2RvcmhDzztFJ49ur4JPlBiOr465808KUZ5P0BaO79pbqa9Wf9ePp7+Iz8da5I5EJdXv/YLCj9wseQ5XJLyPpTH5b3tpWI8mZRfP89sRj8EoyU+tFhhvgTcET9YqzG/3PoBvpZWhrrPazU/y7kPOc/cdr8tkoc+gukCOkZtA71wL0U94HcNP0QdbT8Bfrm9WNAjvtV/qD7ZgoS9NDsCM24rRTKtdn8/JGcyPvkNAr30Cp49ly17P2k3pD12zLy+L9smPOkObT+GC3e80weJPg169rywgnY/2CRxvsxvlT7hZQE+wBlrP6KbJL8jOYi+GOGMvkTSKT9d6Jg98xM1P+JKQb67Vi0/ti+APvnhDr4E5DQ9oP90P1P7KT7aCsg8vuCevZiWez8Fbwi/q/3kPpW+7D7/tgw/cFKlPS82NL/S/YI+llooP/m0hzwhCfs+xp8YvGoQXz9j6Ni+JAinuQ/GHTpC5Gc/19N+vzlVhb1nhAM86GyOPcubFD5HLDq+lA7ePE3heD+0XTu/D2+IveRLfj4OjCE/KhiSOYfFV79Lwwk/9NnkOQda7T7xBPS9CrJwPB+9YD/F9EY/scQhPmetXL5+2hE/e+Mvv1ZTBb7JUHm6av82P328DznP3Ha/LZKHPmDpAjoG5+q8HA1IPT/ZDD9WL20/ywnFvaEbFr6Rdqo+4YKEvdQOj7I0WJgyrXZ/P719LD5ydw29mmCYPXR3ez99J6Q9+e25vkgUOTwyn20/pWtdvCeJhj7X2fi8gNt2P/jCab5hl5M+/x/7PYD8az8lbCS/SIaJvtlAjr68cyk/NraePULbND9Nj1e+ONcrP0xxgD5bgAm+6GsvPUQsdT9O+yk+3wrIPMDgnr2Ylns/CPYIv0zV4z4KuOs+KhoNP7lDnj3TWTS/dMaDPmAoKD8aKqM81J30PmNNMbxX0WA/2jXTvqXaRrooM8E60jNpP+RDf78rQ4S933UCPHiLHj1TKE8+Y7w1vrytGD3rXnY/+hlAv7zJa7103HA+xHIdP2xDkTnZSli/m/EIP6Rv5Tnx+uc+Pb4BvrTzfzwA3WE/bctHP6thGz6H1VS+qt4RP69PLr+CtgG+kbnEulWpOD+Puw85z9x2vyyShz6R6QI6vgLYvEyQSD0mKgw/svxsP30Ayr2LJgu+b3+tPuGChL2S7xmzjPu0Ma12fz9bbiY+K3cUvfaXkT3KxHs/ZWOkPXOYtb7LaDw8hHRuPxydQ7yMDoM+jPD0vH9Vdz9R3WK+ycCQPnCk9D1z82w/qDgkvyfpir5IuI++/A0pPxGXqj1FbTQ/ds9qvmqIKj9As4A+tysFvlQTKz3uTHU/U/spPuIKyDzE4J69mJZ7P6VZCb9WAuM+TQzrPupVDT+KrpY9YX80v7WbhD4A8ic/8IjEPK/g7T7AMk68J5ZiP+cWzb5YPp66q1geO0uQaj/ObX+/rMaEvaX3AjyEg2E8zZ6BPgaRMb7lED092VxzP8+4RL+QQl69AztZPuPtGT91LZA5DPFYv7fpBz+XHuY5w1/kPijRBr4U+4Q8o5diP9NjSD++ARY+Kd1NvqwHEj8yuCy/EPH5vYHrsrqTWjo/lLsPOc/cdr8skoc+ReoCOlTG1Lxiv0U9zl8LP/5YbD9qG8S9hOEGvmwwsj7TgoS9lqGvstQztjCtdn8/bWcjPmEKF70KBo49Iet7Px6UpD0sJrO+EEU7PF/qbj/u7Da8IyKBPhDL8byZl3c/qIpfvtYkjz5usvE9gnBtPzIeJL/onIu+0XaQvgfaKD+XpbE9+yk0P/LBc76U6Sk/rdOAPp1JA74jMyk9OFp1P0/7KT7MCsg8v+CevZiWez/Fgwm/TqviPrbJ6j6Kaw0/1dOSPTWSNL8KBoU+YtYnPwFW1jybd+o+cfFcvFR0Yz/t98m+wfa6umf3PTs/PWs/51R/v5nGkr20xhA8Nw4aOjzUlT604Cy+yktXPWiScD/hAUi/y5ZUvTnwTD4UxRY/zJWPOZZJWb/9Wwc/JXvmOapp5D5uYQe+X4mFPK6PYj8ujEg/UmMTPmIJSr5lUBI/cFIrv+B57r0XXMm4a987P1i2DznP3Ha/LZKHPpnpAjoQbCq9NBvePDkBET9BLm0/7eJjvVrmCr61dLE+34KEvfS05DKPrQIyrXZ/P9e7Mz6Xlv28FCyfPTkdez/jRKQ95z29vhlzIDxs+Gw/3dd8vDZ1iT6+//S8d3N2P+Hncr7GtpU+E1wCPuvoaj/upSS/IPCHvheUjL7e5ik/7nqYPVgYNT8zvTu+NrUtP8gggD7QQBC+o0o2PbDzdD9U+yk+ywrIPMHgnr2Ylns/4UoIv/JN5T7lB+0+epoMP9/bpj1ULjS/LtKCPmplKD8oRII8iXX8PqyxE7yHql4/dybavt4OZ7nID9g5oJlnP8DMfb+dyAG+IwSAPOvK6Dzt5nU+5LEpvl+JKj0MoXQ/aqA4v3vVpr1fJpY+6E0fP+xPkjnqq1e/YOsJP5K95DkK9/w+b6LkvQyFYTx9s1w/GfVHP/B7DT6Knj6+oW0UP+TJM7/D0Qy+LiWovFi7Mj9s1Q85z9x2vyyShz6C6wI6IZGDvfnhZb0EHDg/QytUP+Ah9z0HEaY+tyLhPt2ChL2FA4iyUOZusq12fz/TRdc933HXvWmvEr3C/Hw/WffIPfiHfjtEKMi7/MF+PzCKnrsncs+8MLawPPbafz8MhFC+O9m7OhJnBz0/fno/i8obv2iTrL6QZLK+RdIgPw3xCT5s0C8/xqOlvksGIz+GZ8I+LhY3PBfDWjtGz2w/9RMwPkul2jxLI6G92Ul7P5vyGL/XdrY+gJq8PuzhHT9W2hy7nfYuv1lo8D7RFg8/Om5WPp1JIT6QUJ68fwF3PzfDbb66n5k+hqM0PuaDaD/d7W8/nZCLPuGpCb3eDFw+i1cSP+AAgL5T8kA+QShCP1hVA7/ML2o8+1eGPqUxUT+QFiA5yJ50v7f0lj6DuQE6YTJVP7Zs+r2tA3c8HCkKPyo6Lz9nyC2+m7csPixLMD8+hVC/o7rDvQWhbL12uxE/dcEPOc/cdr8skoc+sOwCOjy/Bb4kh7e9LQJfP9gpyj0YWBk/aWVLPy7GZrzngoS9ALQOL689BDOtdn8/sP4NPUr+4r27HBK9lRp+P43ZLj1LWVg9aACGPOhffz/ezVg9YOKGvUjOTDtRFX8/C+wIviQjKD4xite8oRp6PxihGr9WsbC+s6O2vgihHz8zP6U+/ywjPwxEYb6oCCo/evdDP0fi87zmdUA9vhokP/3IMD5MzNw8a2ehvcBAez8YoRq/VbGwPq6jtj4IoR8/pNEFvcV5N7+eFZk+TRIhPx57dD4cwCg/gQeGvfLGNT9k6DA8Am4cP10Bor0QnUk/JBtDP/pEEj7lRpC8r5chPyoAWD/Oax291Kd5PeAoCD+VQbq+CUMFPeuhLj4HSGo/WaYPOc/cdr8rkoc+ee4COkyqfj8yM3+9MLn7O9+apD3SdGo+d51oPXtnW7xdwHg/0dgBvzo35r33gxU7hL1aP4rCDznP3Ha/LZKHPr3zAjr8iBC+1HTUOvVSYT+UNII+BeIPv61pPb+nYIk+4IKEvQFfH7Pos5uyrXZ/P8Armjuyr+W9mVlXvZkGfj9IWyY88FpJPciTtDtjrH8/UFCvPaoOgL3T3lo82oh+P1I/zr1hMLY+6zXuvA28bT8ZoRq/VrGwvrOjtr4HoR8/bTs0Pgk2Lz9IGRK+32cxP0o06D7Z83c7Xw+sOvwnZD/4yDA+gMzcPGpnob3AQHs/F6Eav1exsD6xo7Y+B6EfP1/RBb3GeTe/nxWZPkwSIT+Ogp8+thQmP+cVCb4maC4/5IMRPtrN/D5/vfO9WIBZPziARz8U8k09HiTLu8TlHz+ivkA/AFUyviiQYT7TXxg/l2M0vo6+iLzTcf48tNV7P4a0DznP3Ha/LpKHPkLrAjo0V3k/UxcAviyxfDwF10A+ug+3PnKFV70yPqU8XKRuP8jHvb557ji+Fv9kvVXJaD9g4g85z9x2vy6Shz5H5wI6JGoevtOdP70wiV8/ojkaP32Oqb7TYw6/WxHvPuWChL385QYzNQgRs612fz/krB89pFkMvgjfgb313Xw/LMCcvHlv8bxdAGE8WNF/P7wI0T33Lie8La/vO4ukfj8pQa69DEamPsC+tbxrE3E/F6Eav1WxsL61o7a+B6EfP+P9vj1heTM/XtjAvQBfMz+iFYA+sK81PRT9O7wUlXc//cgwPmbM3DxrZ6G9wEB7PxehGr9VsbA+taO2PgehHz+6h+m8NS43vzLInD69kSA/AzXfPqpYKj+z322+G0UPP4sbXD7o8d8+KszLvXkVXj8xkUc/cl2xPvPyLr1wIgU/MLpVP1jFnb190vc9YAsIPyqxAr8xNju83ktrPtAZVD8ixg85z9x2vzCShz4Q7wI6amZ9P/Yi77384Gs89WujvUayTT4HSIE9abNUvBY9ej9Swpu+y2MiPfMncb07MHM/Bq8POc/cdr8ukoc+9ewCOuH6N74C9nC97vQmP7sTYT/Uz3M94ou/PbM97T7pgoS96oKisrA4hrGtdn8/vcx0Phi7aL2bC2S8JSB4PyUXRzqHnw0+7iNUPVwxfT8dBxo9o4PwvRaV57xu8X0/ZAVfvj/cID3UhPw8Dod5PxehGr9XsbC+saO2vgehHz+JF1y+r5E6PwpTGr6r5iE/Ata8Pja3pT1xFwS9sedsP/rIMD5JzNw8Z2ehvcBAez+GIxC/rC7RPp0t2D5fyRQ/gU02Pxy+xL5E96o+Bof3PpFfjDzmphA/zkCmOlYrUz/xaMm9cawlPxXylT0mn0A/Zz4WPyCRrL17Nyo80SFOPxO/Ij/kYQS990XaPJBRRT8mdwu/rJwIPQuq+bwBXVY/KcwPOc/cdr8tkoc+meoCOvtTfr/y23g9anj1u1I0xT10sZQ+S8GGPgjhqr00jGo/goyhvmvXGD2LCai9DNNxP4m6DznQ3Ha/K5KHPgfqAjr+BGW+/+gzPZZYFz9nqm0/IHE9PmaQDD6TTpU+2YKEvZBeNDIMfZoyrXZ/P1fEwzxyuqS5etoHPTfJfz9j/X89fj6xPkMPbj3bLG8/zeEePb//iL68YQ+9b012Pxr13r3okWE7AOJ2PTkCfj+w9SK/g6iPviGJlL6rPSg/+IDoO/ZtNT8YDKm+TJkfP8Oxmj3NRw09e1kru3Idfz+MuVo9zYSYvU0as7yE3H4/t4YDv2si8D52IPg+38AHP62fqT4pnN6+SVpGP7aboj4TlG88O3X4PazTEzwwEn4/z/9uvlNiCj+h4LM9zrFNPyjguD5Ev1y+fr3ZPJIpaD+Z2zk/Ao0ePSYCKL10dC8/QhcRv0bkvj2PBHe8MYZRP+jKDznP3Ha/LZKHPi3rAjqAuH6/3I3DvRjkQDzEztq8QYtJPhksmj4WaYK9Ek5uP122bL4nvPA9NTGqvR9Tdj/Cxg85z9x2vy6Shz4f7AI6XnVnvvovbj22jxg/lexuPyLUPj52mQo+CxCNPteChL1QeJ4xZtaCsq12fz8y4mC7Vu7FulakDz07138/yiuLPRWcsT6MHHc9U/luP5hAJz1Iuom+bkAQvV4tdj/aCpq9BBpmu/hgcT27034/ctAjv2u3i75bd5C+4R8pP7ivrzz5JDQ/mNq0vk+5HT+9JqE99t+UPDQJvLrgKX8/vDokPXJGsr1b4Ym8Acl+P+RqA79RX/A+UV/4PiGkBz/ZXqQ+Gr7fvhxKRz+H3aE+o1luPDWy5z06zBU8g1F+P8iKob4b/w0/jZ6GPchhRD8HyLE+MyZfvusb3DwMZmk/IGE2P0FoID13ayO9+BMzP6k7Db/FFcY9ON1zvKMKVD/GzQ85z9x2vy6Shz4g6gI67YZ+P1xSmD04Pxa8d8GcPaocgT66/Zg+ulyovbqtaj8Z44C+iSzrPSWuqL2+GXU/PtAPOc/cdr8rkoc+uecCOsjbYr7qIF893ZgcPwiCbz+cUS0+l9MEPsUbkD7VgoS9RQI9MyhbUbKtdn8/94/3u6SvvbwZGAk91Md/P5iwgz0DZZI+GxFvPY9NdD+IjTU9Hadovq/YEr2q4Hg/uh1oveHEQDwCoUM9Okd/P3LQI79xt4u+VHeQvuAfKT80RtS8K700P7/1v76Iqhk/wpjOPYiWOrk+hd85sLF+P+86JD17RrK9V+GJvAHJfj/nagO/Tl/wPlRf+D4fpAc/3V6kPhy+374cSkc/ht2hPtdZbjw0suc9RcwVPIRRfj/AEJy+oHsSP15TCD0ZuUI/GGO7PgfbYL7Zyt08WWhnP1OdLz/Vn009xcxCvZpsOT87vgm/MJWaPRRUa7zK4lY/8c4POc/cdr8tkoc+1uoCOmCGfj+mYSM9JiihuwWGyz1PZpY+WfqVPnjDwr0uqGc/FleEvqPZ1D1f1qS9CgB1P4jODznQ3Ha/K5KHPt7nAjp4Dzy+5DY2PSkuMT8MBW4/ihQJPvFt1T0QSqc+0YKEvRRoYLJsx/cyrXZ/P0veCbwIKPa8BQrpPI3Ffz+tQoA9JeBjPvedSz1svXg/pS08PUMhOL5wKQC9zGx7P2FrE702Esw8nJIVPXCVfz+8yCK/05+SvovTl75RCCc/5IDFvWJaND9oMtK+8yASP7yTFD5Q/NI7YBSAOhRJfT+5P0Y9CQ2avbmojbx4734/pecHv7W75j7Mbu8+GF8LPwlkoD7y7vK+7xk9P8JguT5Ev3k9PSoMPiZ9nzoCHH0/SkeXvs9hAz+TDY+8iDxOP36//j7J/1S+ERnSPNJ7Vz8Y4hw/o2ahPdZqfL0Sq0g/suMMvxSr4zy6Ct28WoNVP5XQDznP3Ha/LZKHPh3qAjomOmo/yx0cvlP9mTyuEr8+CNAUP1ZKjz6B72O+eRw7P6wuJr/4uD480fflvNySQj9Lzg85z9x2vy6Shz6t5gI6lkHqvfofFT1uP00/0H9nP4ecnz2Kv1Y9yTjVPuuChL3OEI4xIOQMsq12fz95bLG70vFNvAr4szwM6n8/I6KFPWjcLj48eRM9dIR7PzF6Mz2bWQq+rBO6vH1WfT8fzTG8JT7BPLc2vzwL2H8/fRsgv1Icor4Orai+D+whP0h0Mb6sVTI/SW3lvtxmCD9MuUo+9wyUPMUTuzn243o/MWaKPdOIRL2NSJy8kBJ/P2mwEb84v88+9IzZPoZFEz8TOkM+HLsRv7VKKj+RTuM+V5MqPsBv+j2g5Ga82HJ6P/24Y74/17A+k7ygvT6JaD+9iTE/m1sZvs9ElzwVWDQ/XeLvPs6fwT298U69Cn5gP7BtB7+rRBq9E2pgvZ+TWD/FJxU5ZCh2v4CajD79iwI6mNxfP1i+P76xIb0809DkPpbH+z5TH68+PpRfvt44RT90yES/20PEvbncRb1/bCE/vdoPOdDcdr8qkoc+VuwCOpGEZ71ZQvg8hVhYP+q+Wz+YvRU8ty/au4pMAz/dgoS9FmfwsdBrRy6tdn8/uqO3umSCOzzLf208wvR/P8SYkj2c2AA+O3ywPE8+fT8WXB09QmjAvYhzWby9p34/DGxXPCx9RjxZEgg8RPN/P6+hHL99mrK+zjS7vrHGGz/9vXW+GkYvP6uC9L5Guv0+oNd7PhdIAT38+f66QgF4PzUltj0bU5G8BTy2vKfhfj9hmBu/dwy1PlQ3vz6O4xo/2T91vda4Jr/aVhU/Apn2PjDfkD5qjQg83VosOmiHdT8G/Ha9UesRPiPwRb03nXw/sr1KP1Zpjj25eAy8ckYbP2fi0T6oHQi9Jbh0PMdQaT+A9sq+XMetPGm2Qz0wpWo/V0VROQA7bL8LS8U+7Y/6OTVBcT/0fxa+I3OUPNOOmT7+Ab8+MUqwPh0ZG75FH1k/ya0yv/YGJL5eWuy9wTkwP3LdDznQ3Ha/KpKHPsPrAjqAoNG8XGCgPBasWT/zPU4/VdJKvbS7Tr0CkxY/4YKEvZhGN7IcvrczrXZ/P4o0TztW+sY8JKnsO6Hqfz+2y6I9D7OqPa1+ITynSH4/0jwAPS0gbL0qHLe7z3F/P6S8ODzWDR89xEaeO6PJfz/j6Bm/Q5O9vgbpx742PBc/4bWPvsDPLD+gv/y+3ibxPrRKjT5bfik9AuORuxfUdT/6fNQ91TlRO7s8zrwViX4/kdEhvwrsoT7Xyas+VG4fP1jrhr76xC2/hD76PhEK9j4T7LY+/qYDvgFvTT3bemw/wr+7PaZTnTzLk/E8RMN+Pyu7Yj+zKx0+jwebvD0o4D6Cop4+C5vRvZNzCT3t1XE/8ZHZvrBF9Ty9MsY950dmP+KNMzkynHG/Xz2pPvYiADpDlHc/6gMevuncmzwuKE4+uOapPnG+rD4DjwO+3BtfP7WoKL/+l1++11wivpXFMz+11g850Nx2vyqShz477AI6C7gUvMsZ5DsbIVs/lodFP+Dtk72AdoK9ZvcgP9uChL394J4yRK5Ssa12fz/SwxY8jBNmPLlnFjuY9n8/5HywPftjKT0M0l07jdN+P+UeyjxUyeS8cqHDumjSfz8sCJw7KciMPYpfETsSZH8/CXkZvxc2v74y1cm+NYYWP1Ovkr4hbCw/0tz9vj1M7z4IhI8+cqYvPXpAoLsefXU/HRvZPU/r0DvvUtK8p3d+P6i3Ir+M+J4+P8CoPoIRID+qopa+TD8uv6ZL8D4HfPU+zgm8PsRgHb5Tmnw9Qk5qPyMF7z0kJj87s2k3Pav9fT+1uG8/4HYGPgGihLzYZqY+4UB1PjXL3L14Ods8w+p2P7z1975nZFE7MteuPbHnXj8y2A85z9x2vyyShz5o7AI6rZt6P9A9I75+BKE8PwsBPjVikz59Jaw+g7bevSHdYz/R6iK/cdBuvqyQP75bCDY/q94POc/cdr8skoc+iewCOqyZqzogXFs7KZheP+o9Qj/xL6G9FuCJvVqhJD/fgoS9UvQ/MioF2y+tdn8/9UBhPNQ2fTtfiQM6T/l/PwTHuT2U6To8CDFSOoLtfj+su6Q8gwT8u1VLnLnP8H8/stTnOQa7tT3KXpK6bv1+Pwh5Gb8aNr++MNXJvjWGFj9ar5K+IWwsP8vc/b5ATO8+D4SPPpymLz1aQaC7HX11Pxsb2T1m69A751LSvKd3fj+ntyK/kPiePkHAqD6BESA/sKKWvks/Lr+mS/A+BXz1PswJvD7DYB2+LZp8PUNOaj8qBe897CY/O7hpNz2r/X0/PLd0P9kC7T1oyGm8D/mJPoRZVD5RpuK9UmbBPAXBeD+/o/u+lPmeus6Knz2WDV4/99YPOc/cdr8tkoc+h+sCOhUvfT89ogy+w7eKPM0QVj17b0U+YTayPjlRlr2/G2o/Jdsavxo6Zb7C6Vy+cqw7P8bZDznQ3Ha/KJKHPlDrAjqPMqY7xAwaPF2OYD/Sw0E/nA+jvZP6ir3tJSU/2YKEvQzRhDGO+t0wrXZ/P93yezyQJAI5LUCCOUD4fz8fGr09OeOjORDxhjkH6H4/e2CXPBxReLntH365z/R/Pwrjirp7osQ9geIxu/PQfj8IeRm/GTa/vjLVyb40hhY/Vq+SviBsLD/P3P2+QEzvPgyEjz6Npi89mECgux19dT8fG9k9BuzQO+xS0rynd34/qLciv474nj5BwKg+gREgP6+ilr5LPy6/pkvwPgZ89T7OCbw+x2AdvkiafD1CTmo/IQXvPTAlPzvBaTc9q/19P0Smdj8CbN090WdavKeDej5+Zzw+glrmvUaTrTz96nk/jML7vpMq/roXL5o96RNeP7bVDznP3Ha/LJKHPm3sAjoOaX4/QMjhveG0Xjy4s9M7iXPfPQ7itz5kYy29ughtPxCOE787+Vi+K4VtvqMeQT+E4g850Nx2vyqShz7r6gI6"

const FEMALE_LEGENDS: Array = ["wraith", "lifeline", "bangalore", "ash", "horizon", "valkyrie"]

static var _mocap_loaded: bool = false
static var _mocap_floats: PackedFloat32Array = PackedFloat32Array()
static var _male_packed: PackedScene = null
static var _female_packed: PackedScene = null
static var _lower_body_meshes: Dictionary = {}


static func _get_first_person_lower_body_mesh(src_mesh: Mesh) -> Mesh:
	## Battlefield 1 / V & CS2 Full-Body Awareness Lower-Body Mesh Filter:
	## Retains Pelvis (`1`), Lower Spine (`2`), and Both Legs & Feet (`55..64`: thigh/calf/foot/ball)
	## while stripping Upper Chest/Shoulders/Head (`3..6`) and 3rd-Person Arms (`7..54`) so looking
	## down or sliding in 1st-person clearly shows your own character's waist, thighs, knees, and boots
	## on the ground with ZERO shoulder-cuff or chest camera clipping!
	if src_mesh == null:
		return null
	var rid_key: int = src_mesh.get_rid().get_id()
	if _lower_body_meshes.has(rid_key):
		return _lower_body_meshes[rid_key]
	var arr_mesh := ArrayMesh.new()
	var surf_count: int = src_mesh.get_surface_count()
	for s_i in range(surf_count):
		var arrays: Array = src_mesh.surface_get_arrays(s_i)
		if arrays.is_empty():
			continue
		var bones_arr: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights_arr: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var indices_arr: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var verts_arr: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var v_count: int = verts_arr.size()
		if v_count == 0 or indices_arr.is_empty() or bones_arr.is_empty():
			continue
		var bones_per_v: int = 8 if bones_arr.size() == v_count * 8 else 4
		var is_lower_vert := PackedByteArray()
		is_lower_vert.resize(v_count)
		for v_i in range(v_count):
			var lower_w: float = 0.0
			var base_b: int = v_i * bones_per_v
			for j in range(bones_per_v):
				var b_idx: int = bones_arr[base_b + j]
				var w: float = weights_arr[base_b + j]
				if b_idx == 1 or b_idx == 2 or (b_idx >= 55 and b_idx <= 64):
					lower_w += w
			is_lower_vert[v_i] = 1 if lower_w >= 0.50 else 0
		var new_indices := PackedInt32Array()
		for i_idx in range(0, indices_arr.size(), 3):
			var i0: int = indices_arr[i_idx]
			var i1: int = indices_arr[i_idx + 1]
			var i2: int = indices_arr[i_idx + 2]
			if is_lower_vert[i0] == 1 and is_lower_vert[i1] == 1 and is_lower_vert[i2] == 1:
				new_indices.append(i0)
				new_indices.append(i1)
				new_indices.append(i2)
		if new_indices.size() >= 3:
			arrays[Mesh.ARRAY_INDEX] = new_indices
			arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_lower_body_meshes[rid_key] = arr_mesh
	return arr_mesh


static var _sculpted_fp_arm_cache: Dictionary = {}


static func get_sculpted_fp_arm_mesh(is_female: bool, is_left: bool) -> ArrayMesh:
	## Extracts the EXACT 3D sculpted character Arm + Wrist + Palm + 5 Articulated Fingers mesh
	## from `Mannequin_F.glb` (female Legends) or `UAL1_Standard.glb` (male/robot Legends),
	## curls the phalanges into an anatomical weapon/heirloom grip (with right index finger on the trigger),
	## and transforms into `LeftArmPivot` / `RightArmPivot` local space with determinant +1.0!
	## Guarantees 100% visual & geometric consistency between 1st-person and 3rd-person hand models!
	var cache_key: String = ("%s_%s" % ["F" if is_female else "M", "L" if is_left else "R"])
	if _sculpted_fp_arm_cache.has(cache_key):
		return _sculpted_fp_arm_cache[cache_key]

	var temp_model := _instantiate_character_model(is_female)
	if temp_model == null:
		return null
	var src_mesh: Mesh = null
	for child in temp_model.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi != null and mi.mesh != null:
			src_mesh = mi.mesh
			break
	temp_model.free()
	if src_mesh == null:
		return null

	var wrist_rest := Vector3(0.7389, 1.4408, -0.0654) if is_left else Vector3(-0.7389, 1.4408, -0.0654)
	var b_min: int = 8 if is_left else 32
	var b_max: int = 30 if is_left else 54
	var f_min: int = 11 if is_left else 35
	var f_max: int = 26 if is_left else 50
	var idx_min: int = 11 if is_left else 35
	var idx_max: int = 14 if is_left else 38
	var th_min: int = 27 if is_left else 51
	var th_max: int = 30 if is_left else 54

	var arr_mesh := ArrayMesh.new()
	var surf_count: int = src_mesh.get_surface_count()
	for s_i in range(surf_count):
		var arrays: Array = src_mesh.surface_get_arrays(s_i)
		if arrays.is_empty():
			continue
		var bones_arr: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights_arr: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var indices_arr: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var verts_arr: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var norms_arr: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var v_count: int = verts_arr.size()
		if v_count == 0 or indices_arr.is_empty() or bones_arr.is_empty():
			continue
		var bones_per_v: int = 8 if bones_arr.size() == v_count * 8 else 4
		var is_arm_v := PackedByteArray()
		is_arm_v.resize(v_count)
		var new_verts := PackedVector3Array()
		new_verts.resize(v_count)
		var new_norms := PackedVector3Array()
		if norms_arr.size() == v_count:
			new_norms.resize(v_count)

		for v_i in range(v_count):
			var arm_w: float = 0.0
			var finger_w: float = 0.0
			var index_w: float = 0.0
			var thumb_w: float = 0.0
			var uarm_w: float = 0.0
			var base_b: int = v_i * bones_per_v
			for j in range(bones_per_v):
				var b_idx: int = bones_arr[base_b + j]
				var w: float = weights_arr[base_b + j]
				if b_idx >= b_min and b_idx <= b_max:
					arm_w += w
				if b_idx >= f_min and b_idx <= f_max:
					finger_w += w
				if b_idx >= idx_min and b_idx <= idx_max:
					index_w += w
				if b_idx >= th_min and b_idx <= th_max:
					thumb_w += w
				if b_idx == b_min:
					uarm_w += w
			if arm_w < 0.45:
				is_arm_v[v_i] = 0
				new_verts[v_i] = Vector3.ZERO
				continue
			is_arm_v[v_i] = 1
			var d: Vector3 = verts_arr[v_i] - wrist_rest
			var n: Vector3 = norms_arr[v_i] if norms_arr.size() == v_count else Vector3.UP
			var axial: float = d.x if is_left else -d.x

			# 1. Anatomical Finger Curl around Grip Handle (dx > 0.102m past wrist)
			if finger_w > 0.25 and axial > 0.100:
				var s_f: float = axial - 0.100
				var curl_rate: float = 12.5 if (not is_left and index_w > 0.45) else 21.5
				var max_ang: float = 1.32 if (not is_left and index_w > 0.45) else 2.32
				var theta: float = clampf(s_f * curl_rate, 0.0, max_ang) * clampf(finger_w, 0.0, 1.0)
				var r_grip: float = 0.026
				var curled_axial: float = 0.100 + r_grip * sin(theta) + (d.y + 0.008) * sin(theta) * 0.45
				var curled_y: float = -0.008 - r_grip * (1.0 - cos(theta)) + (d.y + 0.008) * cos(theta)
				d.x = curled_axial if is_left else -curled_axial
				d.y = curled_y
				var ct: float = cos(theta)
				var st: float = sin(theta) if is_left else -sin(theta)
				n = Vector3(n.x * ct + n.y * st, -n.x * st + n.y * ct, n.z).normalized()
			elif thumb_w > 0.25 and axial > 0.032:
				var s_t: float = axial - 0.032
				d.y -= s_t * 0.28 * thumb_w
				d.z -= s_t * 0.35 * thumb_w
			elif uarm_w > 0.15 and axial < -0.270:
				# Subtle natural elbow bend toward off-screen shoulder
				var s_u: float = (-0.270 - axial) * uarm_w
				d.y -= s_u * 0.36
				d.z -= s_u * 0.18

			# 2. Pure Right-Handed Orthogonal Rotation (det = +1.0) into LeftArmPivot / RightArmPivot space:
			#    LeftArmPivot:  (local_x, local_y, local_z) = (-d.y,  d.z, -d.x)
			#    RightArmPivot: (local_x, local_y, local_z) = ( d.y,  d.z,  d.x)
			if is_left:
				new_verts[v_i] = Vector3(-d.y, d.z, -d.x)
				if new_norms.size() == v_count:
					new_norms[v_i] = Vector3(-n.y, n.z, -n.x).normalized()
			else:
				new_verts[v_i] = Vector3(d.y, d.z, d.x)
				if new_norms.size() == v_count:
					new_norms[v_i] = Vector3(n.y, n.z, n.x).normalized()

		var new_indices := PackedInt32Array()
		for i_idx in range(0, indices_arr.size(), 3):
			var i0: int = indices_arr[i_idx]
			var i1: int = indices_arr[i_idx + 1]
			var i2: int = indices_arr[i_idx + 2]
			if is_arm_v[i0] == 1 and is_arm_v[i1] == 1 and is_arm_v[i2] == 1:
				new_indices.append(i0)
				new_indices.append(i1)
				new_indices.append(i2)
		if new_indices.size() >= 3:
			var out_arrays := Array()
			out_arrays.resize(Mesh.ARRAY_MAX)
			out_arrays[Mesh.ARRAY_VERTEX] = new_verts
			if new_norms.size() == v_count:
				out_arrays[Mesh.ARRAY_NORMAL] = new_norms
			if arrays[Mesh.ARRAY_TEX_UV] != null:
				out_arrays[Mesh.ARRAY_TEX_UV] = arrays[Mesh.ARRAY_TEX_UV]
			out_arrays[Mesh.ARRAY_INDEX] = new_indices
			arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out_arrays)

	_sculpted_fp_arm_cache[cache_key] = arr_mesh
	return arr_mesh


static func _ensure_mocap_bank_loaded() -> void:
	if _mocap_loaded and _mocap_floats.size() >= 263:
		return
	_mocap_loaded = true
	var raw_bytes: PackedByteArray = Marshalls.base64_to_raw(MOCAP_FLOATS_B64)
	_mocap_floats = raw_bytes.to_float32_array()


static func _make_mat(col: Color, met: float = 0.5, rough: float = 0.4, emit: bool = false, emit_col: Color = Color.BLACK, emit_energy: float = 1.0, pbr_kind: String = "") -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = met
	m.roughness = rough
	if emit:
		m.emission_enabled = true
		m.emission = emit_col
		m.emission_energy_multiplier = emit_energy
	else:
		var kind: String = pbr_kind
		if kind == "":
			if rough >= 0.55:
				kind = "carbon_weave"
			elif met >= 0.70:
				kind = "gunmetal"
			else:
				kind = "polymer_grip"
		m.normal_enabled = true
		m.normal_scale = 0.14 if kind == "gunmetal" else 0.18
		m.normal_texture = CanyonWorldBuilder.get_procedural_normal_tex(kind)
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(16.0, 16.0, 16.0)
		m.rim_enabled = true
		m.rim = 0.24
		m.rim_tint = 0.35
	return m


static func _add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, name: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if name != "":
		mi.name = name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func _add_cyl(parent: Node3D, top_r: float, bot_r: float, h: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, segs: int = 14, name: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if name != "":
		mi.name = name
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	cm.radial_segments = segs
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func _add_capsule(parent: Node3D, rad: float, h: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, name: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if name != "":
		mi.name = name
	var cap := CapsuleMesh.new()
	cap.radius = rad
	cap.height = maxf(rad * 2.02, h)
	cap.radial_segments = 14
	cap.rings = 6
	mi.mesh = cap
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func _add_sphere(parent: Node3D, rad: float, pos: Vector3, mat: Material, name: String = "", scale_v: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if name != "":
		mi.name = name
	var sm := SphereMesh.new()
	sm.radius = rad
	sm.height = rad * 2.0
	sm.radial_segments = 14
	sm.rings = 8
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	mi.scale = scale_v
	parent.add_child(mi)
	return mi


static func _instantiate_character_model(is_female: bool) -> Node3D:
	var fem_paths: Array = ["res://assets/animations/Mannequin_F.glb", "res://assets/models/character/Mannequin_F.glb"]
	var male_paths: Array = ["res://assets/animations/UAL1_Standard.glb", "res://assets/models/character/UAL1_Standard.glb"]
	var search_paths: Array = (fem_paths + male_paths) if is_female else male_paths

	if is_female and _female_packed != null:
		var inst_f := _female_packed.instantiate() as Node3D
		if inst_f != null:
			return inst_f
	elif (not is_female) and _male_packed != null:
		var inst_m := _male_packed.instantiate() as Node3D
		if inst_m != null:
			return inst_m

	for p_item in search_paths:
		var p: String = str(p_item)
		if ResourceLoader.exists(p):
			var res := load(p)
			if res is PackedScene:
				if is_female and "Mannequin_F" in p:
					_female_packed = res
				elif "UAL1_Standard" in p:
					_male_packed = res
				var inst := (res as PackedScene).instantiate() as Node3D
				if inst != null:
					return inst
		if FileAccess.file_exists(p):
			var doc := GLTFDocument.new()
			var state := GLTFState.new()
			if doc.append_from_file(ProjectSettings.globalize_path(p), state) == OK:
				var gen := doc.generate_scene(state) as Node3D
				if gen != null:
					return gen
	return null


static func _build_bone_map(skel: Skeleton3D) -> PackedInt32Array:
	var bmap := PackedInt32Array()
	bmap.resize(65)
	for i in range(65):
		bmap[i] = skel.find_bone(str(BONE_NAMES_65[i])) if skel != null else -1
	return bmap


static func _apply_base_65_pose(skel: Skeleton3D, bone_map: PackedInt32Array) -> void:
	if skel == null or bone_map.size() < 65:
		return
	_ensure_mocap_bank_loaded()
	if _mocap_floats.size() < 263:
		return
	var pel_idx: int = bone_map[1]
	if pel_idx >= 0:
		skel.set_bone_pose_position(pel_idx, Vector3(_mocap_floats[0], _mocap_floats[1], _mocap_floats[2]))
	for b_i in range(65):
		var skel_b: int = bone_map[b_i]
		if skel_b < 0:
			continue
		var o: int = 3 + b_i * 4
		skel.set_bone_pose_rotation(skel_b, Quaternion(_mocap_floats[o], _mocap_floats[o + 1], _mocap_floats[o + 2], _mocap_floats[o + 3]))


static func _sample_mocap_clip_to_skeleton(skel: Skeleton3D, bone_map: PackedInt32Array, clip_name: String, sample_time: float, loop: bool = true) -> bool:
	if skel == null or bone_map.size() < 65:
		return false
	_ensure_mocap_bank_loaded()
	if _mocap_floats.size() < 263:
		return false
	var meta: Dictionary = MOCAP_CLIPS_META.get(clip_name, MOCAP_CLIPS_META.get("Pistol_Idle_Loop", {}))
	if meta.is_empty():
		return false
	var base_offset: int = int(meta["offset"])
	var num_frames: int = int(meta["frames"])
	var duration: float = maxf(0.001, float(meta["dur"]))
	var t_norm: float = (fposmod(sample_time, duration) / duration) if loop else clampf(sample_time / duration, 0.0, 1.0)
	var f_exact: float = t_norm * float(max(0, num_frames - 1))
	var f0: int = clampi(int(floor(f_exact)), 0, num_frames - 1)
	var f1: int = clampi(f0 + 1, 0, num_frames - 1)
	var frac: float = clampf(f_exact - float(f0), 0.0, 1.0)
	var base0: int = base_offset + f0 * 91
	var base1: int = base_offset + f1 * 91

	var pel_idx: int = bone_map[1]
	if pel_idx >= 0:
		var px: float = lerpf(_mocap_floats[base0 + 0], _mocap_floats[base1 + 0], frac)
		var py: float = lerpf(_mocap_floats[base0 + 1], _mocap_floats[base1 + 1], frac)
		var pz: float = lerpf(_mocap_floats[base0 + 2], _mocap_floats[base1 + 2], frac)
		skel.set_bone_pose_position(pel_idx, Vector3(px, py, pz))

	for k_i in range(22):
		var b_i: int = int(ACTIVE_22_BONES[k_i])
		var skel_b: int = bone_map[b_i]
		if skel_b < 0:
			continue
		var o0: int = base0 + 3 + k_i * 4
		var o1: int = base1 + 3 + k_i * 4
		var q0 := Quaternion(_mocap_floats[o0], _mocap_floats[o0 + 1], _mocap_floats[o0 + 2], _mocap_floats[o0 + 3])
		var q1 := Quaternion(_mocap_floats[o1], _mocap_floats[o1 + 1], _mocap_floats[o1 + 2], _mocap_floats[o1 + 3])
		skel.set_bone_pose_rotation(skel_b, q0.slerp(q1, frac))
	return true


static func _set_subtree_fp_shadow_mode(node: Node3D, active_in_3p: bool, is_first_person: bool) -> void:
	## In 3rd-person (`is_first_person == false`): normal visibility (`SHADOW_CASTING_SETTING_ON`).
	## In 1st-person (`is_first_person == true`): keeps `node.visible = active_in_3p` and switches all
	## child `MeshInstance3D` nodes to `SHADOW_CASTING_SETTING_SHADOWS_ONLY` so the player casts a complete
	## full-body + helmet + armor + weapon shadow on the ground with ZERO camera clipping!
	if node == null:
		return
	if not active_in_3p:
		node.visible = false
		return
	node.visible = true
	var target_mode := GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if is_first_person else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if node is MeshInstance3D:
		(node as MeshInstance3D).cast_shadow = target_mode
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi != null:
			mi.cast_shadow = target_mode


static func _sample_upper_body_clip_only(skel: Skeleton3D, bone_map: PackedInt32Array, clip_name: String, sample_time: float, loop: bool = true) -> Quaternion:
	## Samples ONLY upper-body bones (`spine_01..hand_r`, `k_i = 1..13` in `ACTIVE_22_BONES`) from `clip_name`
	## while leaving `pelvis` (`k_i = 0`) and both legs (`k_i = 14..21`) untouched so lower-body locomotion continues!
	## Returns the sampled clip's reference `pelvis` quaternion for pelvis-decoupling compensation.
	_ensure_mocap_bank_loaded()
	if skel == null or bone_map.size() < 65 or _mocap_floats.size() < 263:
		return Quaternion.IDENTITY
	var meta: Dictionary = MOCAP_CLIPS_META.get(clip_name, MOCAP_CLIPS_META.get("Pistol_Idle_Loop", {}))
	if meta.is_empty():
		return Quaternion.IDENTITY
	var base_offset: int = int(meta["offset"])
	var num_frames: int = int(meta["frames"])
	var duration: float = maxf(0.001, float(meta["dur"]))
	var t_norm: float = (fposmod(sample_time, duration) / duration) if loop else clampf(sample_time / duration, 0.0, 1.0)
	var f_exact: float = t_norm * float(max(0, num_frames - 1))
	var f0: int = clampi(int(floor(f_exact)), 0, num_frames - 1)
	var f1: int = clampi(f0 + 1, 0, num_frames - 1)
	var frac: float = clampf(f_exact - float(f0), 0.0, 1.0)
	var base0: int = base_offset + f0 * 91
	var base1: int = base_offset + f1 * 91

	# Sample reference pelvis rotation of the upper-body clip (`k_i = 0`)
	var op0: int = base0 + 3
	var op1: int = base1 + 3
	var qp0 := Quaternion(_mocap_floats[op0], _mocap_floats[op0 + 1], _mocap_floats[op0 + 2], _mocap_floats[op0 + 3])
	var qp1 := Quaternion(_mocap_floats[op1], _mocap_floats[op1 + 1], _mocap_floats[op1 + 2], _mocap_floats[op1 + 3])
	var q_pelvis_ref: Quaternion = qp0.slerp(qp1, frac)

	# Apply upper-body bones (`k_i = 1..13` -> `spine_01..hand_r`)
	for k_i in range(1, 14):
		var b_i: int = int(ACTIVE_22_BONES[k_i])
		var skel_b: int = bone_map[b_i]
		if skel_b < 0:
			continue
		var o0: int = base0 + 3 + k_i * 4
		var o1: int = base1 + 3 + k_i * 4
		var q0 := Quaternion(_mocap_floats[o0], _mocap_floats[o0 + 1], _mocap_floats[o0 + 2], _mocap_floats[o0 + 3])
		var q1 := Quaternion(_mocap_floats[o1], _mocap_floats[o1 + 1], _mocap_floats[o1 + 2], _mocap_floats[o1 + 3])
		skel.set_bone_pose_rotation(skel_b, q0.slerp(q1, frac))
	return q_pelvis_ref


static func _mult_bone_rot(skel: Skeleton3D, bone_map: PackedInt32Array, b_i: int, q_delta: Quaternion) -> void:
	var skel_b: int = bone_map[b_i]
	if skel_b >= 0:
		skel.set_bone_pose_rotation(skel_b, skel.get_bone_pose_rotation(skel_b) * q_delta)


static func _apply_upper_body_rifle_combat_stance(skel: Skeleton3D, bone_map: PackedInt32Array, aim_time: float, bob_phase: float, is_moving: bool, is_ads: bool, is_firing: bool) -> Quaternion:
	## IK-Solved Two-Handed Rifle/SMG Shoulder-Pocket Combat Stance (Replaces stiff arcade 2-arm pistol pose!):
	## - Right hand (`hand_r`) tucks the pistol grip & stock near the right shoulder pocket (`[-0.19, 1.32, 0.31]`),
	## - Left support hand (`hand_l`) extends forward to cradle the barrel handguard (`[-0.15, 1.29, 0.47]`),
	## - Adds rhythmic walk/jog tactical gait sway and high-frequency 3rd-person firing recoil impulse!
	var q_pelvis_ref: Quaternion = _sample_upper_body_clip_only(skel, bone_map, "Pistol_Idle_Loop", aim_time, true)

	# IK-Solved Rifle Shoulder-Pocket Delta Quaternions
	_mult_bone_rot(skel, bone_map, 32, Quaternion(-0.1504, -0.0186, 0.2781, 0.9485))
	_mult_bone_rot(skel, bone_map, 33, Quaternion(0.5994, -0.0231, -0.0206, 0.7998))
	_mult_bone_rot(skel, bone_map, 34, Quaternion(-0.2506, -0.0696, -0.2069, 0.9432))
	_mult_bone_rot(skel, bone_map, 8, Quaternion(0.1232, -0.0049, 0.1193, 0.9852))
	_mult_bone_rot(skel, bone_map, 9, Quaternion(-0.2623, 0.0, 0.0066, 0.9650))

	# ADS Cheek-Weld tightening
	if is_ads:
		_mult_bone_rot(skel, bone_map, 6, Quaternion(Vector3.FORWARD, 0.12) * Quaternion(Vector3.RIGHT, 0.06))
		_mult_bone_rot(skel, bone_map, 32, Quaternion(Vector3.RIGHT, 0.05))
		_mult_bone_rot(skel, bone_map, 8, Quaternion(Vector3.RIGHT, 0.04))

	# Walking / Jogging Tactical Gait Counter-Sway
	if is_moving:
		var walk_sway_x: float = sin(bob_phase) * (0.012 if is_ads else 0.032)
		var walk_sway_z: float = cos(bob_phase * 0.5) * (0.008 if is_ads else 0.022)
		_mult_bone_rot(skel, bone_map, 32, Quaternion(Vector3.RIGHT, walk_sway_x) * Quaternion(Vector3.FORWARD, walk_sway_z))
		_mult_bone_rot(skel, bone_map, 8, Quaternion(Vector3.RIGHT, walk_sway_x) * Quaternion(Vector3.FORWARD, -walk_sway_z))

	# 3rd-Person Multi-Axis Firing Recoil Impulse (Shoulder Kick + Muzzle Rise)
	if is_firing:
		var fire_osc: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.062)
		_mult_bone_rot(skel, bone_map, 4, Quaternion(Vector3.RIGHT, -0.045 * fire_osc))
		_mult_bone_rot(skel, bone_map, 32, Quaternion(Vector3.RIGHT, -0.095 * fire_osc))
		_mult_bone_rot(skel, bone_map, 33, Quaternion(Vector3.RIGHT, 0.11 * fire_osc))
		_mult_bone_rot(skel, bone_map, 34, Quaternion(Vector3.RIGHT, -0.08 * fire_osc))
		_mult_bone_rot(skel, bone_map, 8, Quaternion(Vector3.RIGHT, -0.065 * fire_osc))
	return q_pelvis_ref


static func _apply_upper_body_sprint_carry(skel: Skeleton3D, bone_map: PackedInt32Array, aim_time: float, bob_phase: float) -> Quaternion:
	## Apex Legends / Battlefield V Style Tactical Cross-Chest High-Port Sprint Carry:
	## Angles the weapon diagonally across the chest (~38 deg left, ~23 deg up) and pumps both arms
	## in rhythmic phase with the sprinting stride (`bob_phase`)!
	var q_pelvis_ref: Quaternion = _sample_upper_body_clip_only(skel, bone_map, "Pistol_Idle_Loop", aim_time, true)
	var stride_s: float = sin(bob_phase)
	var stride_c: float = cos(bob_phase * 0.5)

	_mult_bone_rot(skel, bone_map, 3, Quaternion(Vector3.RIGHT, 0.10) * Quaternion(Vector3.UP, stride_s * 0.08))
	_mult_bone_rot(skel, bone_map, 4, Quaternion(Vector3.RIGHT, 0.08) * Quaternion(Vector3.UP, stride_s * 0.10))
	_mult_bone_rot(skel, bone_map, 32, Quaternion(-0.1623, -0.0807, 0.3183, 0.9305) * Quaternion(Vector3.RIGHT, stride_s * 0.11))
	_mult_bone_rot(skel, bone_map, 33, Quaternion(0.5284, -0.0530, 0.1129, 0.8398) * Quaternion(Vector3.RIGHT, absf(stride_s) * 0.08))
	_mult_bone_rot(skel, bone_map, 34, Quaternion(0.1487, -0.0425, 0.0042, 0.9880) * Quaternion(Vector3.FORWARD, stride_c * 0.06))
	_mult_bone_rot(skel, bone_map, 8, Quaternion(-0.2151, -0.0782, -0.0658, 0.9712) * Quaternion(Vector3.RIGHT, -stride_s * 0.10))
	_mult_bone_rot(skel, bone_map, 9, Quaternion(0.2474, 0.0, 0.1049, 0.9632))
	return q_pelvis_ref


static func _apply_upper_body_tactical_reload(skel: Skeleton3D, bone_map: PackedInt32Array, reload_progress: float) -> Quaternion:
	## 4-Stage IK-Solved Two-Handed 3rd-Person Tactical Reload Choreography (`0.0 -> 1.0` single cycle):
	## - Stage 1 (`0.00..0.26`): Right hand cants rifle inward; left hand reaches to magwell & strips empty magazine.
	## - Stage 2 (`0.26..0.52`): Left hand drops down to waist belt ammo pouch (`[0.18, 0.96, 0.08]`) to grab fresh mag.
	## - Stage 3 (`0.52..0.76`): Left hand drives fresh magazine back up into magwell with upward seating impulse.
	## - Stage 4 (`0.76..1.00`): Right hand rolls rifle; left hand reaches up to rack charging handle / bolt release!
	var p: float = clampf(reload_progress, 0.0, 1.0)
	var q_pelvis_ref: Quaternion = _sample_upper_body_clip_only(skel, bone_map, "Pistol_Idle_Loop", p * 1.5, true)

	# Reference IK Quaternions for Combat, Mag-Grab, Hip-Pouch, and Bolt-Rack
	var q32_combat := Quaternion(-0.1504, -0.0186, 0.2781, 0.9485)
	var q33_combat := Quaternion(0.5994, -0.0231, -0.0206, 0.7998)
	var q34_combat := Quaternion(-0.2506, -0.0696, -0.2069, 0.9432)
	var q8_combat := Quaternion(0.1232, -0.0049, 0.1193, 0.9852)
	var q9_combat := Quaternion(-0.2623, 0.0, 0.0066, 0.9650)

	var q32_mag := Quaternion(-0.1330, -0.1012, 0.2180, 0.9615)
	var q33_mag := Quaternion(0.5337, -0.1023, -0.0105, 0.8394)
	var q34_mag := Quaternion(-0.1857, -0.1395, -0.1372, 0.9629)
	var q8_mag := Quaternion(-0.0952, 0.0154, -0.0782, 0.9923)
	var q9_mag := Quaternion(0.1639, 0.0001, -0.0207, 0.9863)

	var q32_pouch := Quaternion(-0.1389, -0.0973, 0.1994, 0.9651)
	var q33_pouch := Quaternion(0.5450, -0.0973, -0.0072, 0.8327)
	var q34_pouch := Quaternion(-0.2114, -0.1365, -0.1354, 0.9583)
	var q8_pouch := Quaternion(-0.3636, 0.2262, -0.2945, 0.8543)
	var q9_pouch := Quaternion(0.0823, 0.0, -0.3142, 0.9458)

	var q32_bolt := Quaternion(-0.1156, -0.0008, 0.2549, 0.9600)
	var q33_bolt := Quaternion(0.5346, 0.0139, 0.0603, 0.8428)
	var q34_bolt := Quaternion(-0.1345, -0.0190, -0.1983, 0.9707)
	var q8_bolt := Quaternion(-0.0434, -0.0070, -0.0174, 0.9989)
	var q9_bolt := Quaternion(0.2833, 0.0, 0.0094, 0.9590)

	var q32: Quaternion = q32_combat
	var q33: Quaternion = q33_combat
	var q34: Quaternion = q34_combat
	var q8: Quaternion = q8_combat
	var q9: Quaternion = q9_combat
	var head_nod: float = 0.0

	if p < 0.24:
		var w1: float = smoothstep(0.0, 0.24, p)
		q32 = q32_combat.slerp(q32_mag, w1)
		q33 = q33_combat.slerp(q33_mag, w1)
		q34 = q34_combat.slerp(q34_mag, w1)
		q8 = q8_combat.slerp(q8_mag, w1)
		q9 = q9_combat.slerp(q9_mag, w1)
		head_nod = 0.14 * w1
	elif p < 0.48:
		var w2: float = smoothstep(0.24, 0.48, p)
		q32 = q32_mag.slerp(q32_pouch, w2)
		q33 = q33_mag.slerp(q33_pouch, w2)
		q34 = q34_mag.slerp(q34_pouch, w2)
		q8 = q8_mag.slerp(q8_pouch, w2)
		q9 = q9_mag.slerp(q9_pouch, w2)
		head_nod = 0.18
	elif p < 0.74:
		var w3: float = smoothstep(0.48, 0.74, p)
		var tap_bump: float = sin(clampf((p - 0.58) / 0.14, 0.0, 1.0) * PI) * 0.08
		q32 = q32_pouch.slerp(q32_mag, w3) * Quaternion(Vector3.RIGHT, -tap_bump)
		q33 = q33_pouch.slerp(q33_mag, w3)
		q34 = q34_pouch.slerp(q34_mag, w3)
		q8 = q8_pouch.slerp(q8_mag, w3)
		q9 = q9_pouch.slerp(q9_mag, w3)
		head_nod = 0.16
	else:
		var w4: float = smoothstep(0.74, 0.88, p) if p < 0.88 else (1.0 - smoothstep(0.88, 1.0, p))
		var w_end: float = smoothstep(0.84, 1.0, p)
		q32 = q32_mag.slerp(q32_combat, w_end).slerp(q32_bolt, w4)
		q33 = q33_mag.slerp(q33_combat, w_end).slerp(q33_bolt, w4)
		q34 = q34_mag.slerp(q34_combat, w_end).slerp(q34_bolt, w4)
		q8 = q8_mag.slerp(q8_combat, w_end).slerp(q8_bolt, w4)
		q9 = q9_mag.slerp(q9_combat, w_end).slerp(q9_bolt, w4)
		head_nod = 0.12 * (1.0 - w_end)

	_mult_bone_rot(skel, bone_map, 6, Quaternion(Vector3.RIGHT, head_nod))
	_mult_bone_rot(skel, bone_map, 32, q32)
	_mult_bone_rot(skel, bone_map, 33, q33)
	_mult_bone_rot(skel, bone_map, 34, q34)
	_mult_bone_rot(skel, bone_map, 8, q8)
	_mult_bone_rot(skel, bone_map, 9, q9)
	return q_pelvis_ref


static func _apply_upper_body_healing_choreography(skel: Skeleton3D, bone_map: PackedInt32Array, anim_time: float) -> Quaternion:
	## Two-Handed Chest-Level Shield Battery Twist & MedKit Injector Choreography (`打药/拧电池全身协调`):
	## Holds `HealPropRoot` up in front of the chest (`y = 1.25m, z = 0.32m`) while the right hand twists
	## the top capacitor cap — allowing the lower body to walk, crouch-walk, or slide simultaneously!
	var q_pelvis_ref: Quaternion = _sample_upper_body_clip_only(skel, bone_map, "Pistol_Idle_Loop", anim_time, true)
	var twist_w: float = sin(anim_time * 6.5)
	_mult_bone_rot(skel, bone_map, 6, Quaternion(Vector3.RIGHT, 0.16))
	_mult_bone_rot(skel, bone_map, 32, Quaternion(-0.0379, -0.0466, 0.1082, 0.9923) * Quaternion(Vector3.RIGHT, twist_w * 0.05))
	_mult_bone_rot(skel, bone_map, 33, Quaternion(0.4503, 0.0, 0.1897, 0.8725) * Quaternion(Vector3.UP, twist_w * 0.14))
	_mult_bone_rot(skel, bone_map, 8, Quaternion(-0.3119, -0.0111, -0.1859, 0.9317))
	_mult_bone_rot(skel, bone_map, 9, Quaternion(0.3751, 0.0, 0.0149, 0.9268))
	return q_pelvis_ref


static func _apply_upper_body_melee_choreography(skel: Skeleton3D, bone_map: PackedInt32Array, lid: String, is_heirloom: bool, melee_combo_idx: int, melee_prog: float) -> Quaternion:
	## 3-Stage Torso-Driven Upper-Body Melee & Heirloom Slash Choreography (`蓄力拧腰 -> 转肩爆发 -> 收势回防`):
	## Runs on Layer 1 (Upper Body) so the legs continue walking, sprinting, sliding, or jumping underneath!
	var p: float = clampf(melee_prog, 0.0, 0.999)
	var stage: int = posmod(melee_combo_idx, 3)
	var clip_name: String = "Punch_Jab"
	if is_heirloom and lid != "pathfinder":
		clip_name = "Sword_Regular_A" if stage == 0 else ("Sword_Regular_B" if stage == 1 else "Sword_Attack")
	else:
		clip_name = "Punch_Jab" if stage == 0 else ("Punch_Cross" if stage == 1 else "Melee_Hook")

	var c_meta: Dictionary = MOCAP_CLIPS_META.get(clip_name, MOCAP_CLIPS_META.get("Punch_Jab", {}))
	var c_dur: float = float(c_meta.get("dur", 0.6))
	var q_pelvis_ref: Quaternion = _sample_upper_body_clip_only(skel, bone_map, clip_name, p * c_dur, false)

	# Kinetic Torso Windup (0..0.22) -> Whip-Snap Strike Extension (0.22..0.48) -> Damped Guard Return (0.48..1.0)
	var coil_t: float = sin(clampf(p / 0.22, 0.0, 1.0) * PI * 0.5) if p < 0.22 else 0.0
	var snap_t: float = sin(clampf((p - 0.16) / 0.42, 0.0, 1.0) * PI)
	var dir_sign: float = 1.0 if stage == 0 else (-1.0 if stage == 1 else 0.65)
	var torso_yaw: float = (-0.28 * coil_t + 0.52 * snap_t) * dir_sign
	var torso_lean: float = -0.10 * coil_t + 0.26 * snap_t

	_mult_bone_rot(skel, bone_map, 3, Quaternion(Vector3.UP, torso_yaw * 0.55) * Quaternion(Vector3.RIGHT, torso_lean * 0.5))
	_mult_bone_rot(skel, bone_map, 4, Quaternion(Vector3.UP, torso_yaw * 0.65) * Quaternion(Vector3.RIGHT, torso_lean * 0.6))
	if is_heirloom and lid != "pathfinder":
		_mult_bone_rot(skel, bone_map, 32, Quaternion(Vector3.RIGHT, 0.28 * snap_t) * Quaternion(Vector3.UP, 0.22 * snap_t * dir_sign))
		_mult_bone_rot(skel, bone_map, 33, Quaternion(Vector3.RIGHT, -0.22 * snap_t))
	else:
		if stage == 0:
			_mult_bone_rot(skel, bone_map, 8, Quaternion(Vector3.RIGHT, 0.32 * snap_t))
		else:
			_mult_bone_rot(skel, bone_map, 32, Quaternion(Vector3.RIGHT, 0.35 * snap_t))
	return q_pelvis_ref


static func _get_pistol_ref_quat(b_i: int) -> Quaternion:
	_ensure_mocap_bank_loaded()
	if _mocap_floats.size() < 263:
		return Quaternion.IDENTITY
	var o: int = 3 + b_i * 4
	return Quaternion(_mocap_floats[o], _mocap_floats[o + 1], _mocap_floats[o + 2], _mocap_floats[o + 3])


static func _get_legend_body_scale(lid: String) -> Vector3:
	match lid:
		"gibraltar":
			return Vector3(1.24, 1.08, 1.26)
		"caustic":
			return Vector3(1.16, 1.05, 1.18)
		"pathfinder":
			return Vector3(1.04, 1.06, 1.04)
		"bloodhound":
			return Vector3(1.02, 1.01, 1.02)
		"mirage":
			return Vector3(1.00, 1.00, 1.00)
		"bangalore":
			return Vector3(0.97, 1.00, 0.97)
		"horizon":
			return Vector3(0.94, 0.99, 0.94)
		"valkyrie":
			return Vector3(0.93, 0.97, 0.93)
		"octane":
			return Vector3(0.92, 0.97, 0.92)
		"ash":
			return Vector3(0.90, 1.00, 0.90)
		"lifeline":
			return Vector3(0.91, 0.94, 0.91)
		"wraith":
			return Vector3(0.90, 0.95, 0.90)
		_:
			return Vector3.ONE


static func _get_legend_undersuit_color(lid: String) -> Color:
	match lid:
		"wraith":
			return Color("#1e1b4b")
		"octane":
			return Color("#1c1917")
		"bloodhound":
			return Color("#451a03")
		"pathfinder":
			return Color("#334155")
		"lifeline":
			return Color("#f1f5f9")
		"gibraltar":
			return Color("#431407")
		"bangalore":
			return Color("#292524")
		"ash":
			return Color("#cbd5e1")
		"horizon":
			return Color("#f8fafc")
		"valkyrie":
			return Color("#1e1b4b")
		"caustic":
			return Color("#1a2e05")
		"mirage":
			return Color("#27272a")
		_:
			return Color("#1e293b")


static func _build_tp_boxing_glove(parent: Node3D, is_left: bool, h_col: Color) -> void:
	var side_s: float = 1.0 if is_left else -1.0
	var mat_blue := _make_mat(Color("#0284c7"), 0.22, 0.28)
	var mat_navy := _make_mat(Color("#0369a1"), 0.26, 0.34)
	var mat_gold := _make_mat(Color("#facc15"), 0.85, 0.20)
	var mat_red := _make_mat(Color("#ef4444"), 0.40, 0.28)
	var mat_led := _make_mat(h_col, 0.2, 0.1, true, h_col, 3.2)

	var g_root := Node3D.new()
	g_root.name = "TP_LeftBoxingGlove" if is_left else "TP_RightBoxingGlove"
	parent.add_child(g_root)

	_add_cyl(g_root, 0.050, 0.054, 0.11, Vector3(0, 0.02, 0), mat_gold, Vector3.ZERO, 16, "Cuff")
	_add_cyl(g_root, 0.053, 0.055, 0.024, Vector3(0, 0.07, 0), mat_red, Vector3.ZERO, 16, "CuffTrim")
	_add_sphere(g_root, 0.080, Vector3(0, 0.14, 0), mat_blue, "GloveDome", Vector3(1.10, 1.22, 0.90))
	var k_roll := _add_capsule(g_root, 0.046, 0.135, Vector3(0, 0.18, 0.01), mat_blue, Vector3(0, 0, PI * 0.5), "KnuckleRoll")
	k_roll.scale = Vector3(0.88, 1.0, 1.05)
	_add_capsule(g_root, 0.034, 0.10, Vector3(side_s * 0.066, 0.12, 0.02), mat_navy, Vector3(0, 0, -side_s * 0.25), "Thumb")
	_add_cyl(g_root, 0.026, 0.026, 0.01, Vector3(0, 0.04, -0.045), mat_led, Vector3(PI * 0.5, 0, 0), 12, "Badge")


static func _create_bone_att(skel: Skeleton3D, att_name: String, bone_name: String) -> BoneAttachment3D:
	var att := BoneAttachment3D.new()
	att.name = att_name
	att.bone_name = bone_name
	skel.add_child(att)
	return att


static func create_legend_rig(legend_data: Dictionary, weapon_id: String = "r301") -> Node3D:
	_ensure_mocap_bank_loaded()
	var lid: String = str(legend_data.get("id", "wraith"))
	var is_female: bool = lid in FEMALE_LEGENDS
	var root := Node3D.new()
	root.name = "LegendRig_" + lid
	root.set_meta("legend_id", lid)
	root.set_meta("weapon_id", weapon_id)
	root.set_meta("anim_clip", "Pistol_Idle_Loop")
	root.set_meta("anim_time", 0.0)
	root.set_meta("legend_scale", _get_legend_body_scale(lid))

	var col_prim: Color = legend_data.get("primary_color", Color("#312e81"))
	var col_sec: Color = legend_data.get("secondary_color", Color("#38bdf8"))
	var col_visor: Color = legend_data.get("visor_color", Color("#a78bfa"))
	var col_under: Color = _get_legend_undersuit_color(lid)
	var h_info: Dictionary = legend_data.get("heirloom", {"color": Color("#38bdf8")})
	var h_col: Color = h_info.get("color", Color("#38bdf8"))

	var is_robot: bool = (lid == "pathfinder" or lid == "ash")
	var mat_prim := _make_mat(col_prim, 0.72 if is_robot else 0.45, 0.26 if is_robot else 0.42, false, Color.BLACK, 1.0, "gunmetal" if is_robot else "carbon_weave")
	var mat_sec := _make_mat(col_sec, 0.76, 0.24, false, Color.BLACK, 1.0, "gunmetal")
	var mat_under := _make_mat(col_under, 0.65 if is_robot else 0.25, 0.30 if is_robot else 0.62, false, Color.BLACK, 1.0, "polymer_grip")
	var mat_dark := _make_mat(Color("#0f172a"), 0.38, 0.52, false, Color.BLACK, 1.0, "polymer_grip")
	var mat_metal := _make_mat(Color("#cbd5e1"), 0.92, 0.16, false, Color.BLACK, 1.0, "gunmetal")
	var mat_visor := _make_mat(col_visor, 0.2, 0.1, true, col_visor, 3.4)
	var mat_glow := _make_mat(Color("#38bdf8"), 0.1, 0.1, true, Color("#38bdf8"), 4.0)
	var mat_plasma := _make_mat(h_col, 0.3, 0.1, true, h_col, 3.6)

	var wep_data: Dictionary = GameData.get_weapon_by_id(weapon_id if (weapon_id != "empty" and weapon_id != "") else "r301")

	var ual_model := _instantiate_character_model(is_female)
	if ual_model != null:
		ual_model.name = "UALCharacterModel"
		ual_model.rotation.y = PI
		ual_model.scale = _get_legend_body_scale(lid)
		root.add_child(ual_model)

		var skels := ual_model.find_children("*", "Skeleton3D", true, false)
		var skel: Skeleton3D = (skels[0] as Skeleton3D) if not skels.is_empty() else null
		var anim_players := ual_model.find_children("*", "AnimationPlayer", true, false)
		for ap_node in anim_players:
			var ap := ap_node as AnimationPlayer
			if ap != null:
				ap.stop()
				ap.active = false
				if ap.get_parent() != null:
					ap.get_parent().remove_child(ap)
				ap.free()

		for child in ual_model.find_children("*", "MeshInstance3D", true, false):
			var mi := child as MeshInstance3D
			if mi != null and mi.mesh != null and mi.name != "FPShadowCasterBody":
				mi.set_meta("full_mesh", mi.mesh)
				mi.set_meta("lower_body_mesh", _get_first_person_lower_body_mesh(mi.mesh))
				mi.set_meta("mat_0", mat_prim)
				mi.set_meta("mat_1", mat_under)
				mi.set_surface_override_material(0, mat_prim)
				if mi.mesh.get_surface_count() > 1:
					mi.set_surface_override_material(1, mat_under)
				# Dedicated Full-Body Shadow Caster (`SHADOW_CASTING_SETTING_SHADOWS_ONLY`) for 1st-Person!
				# Casts the complete 65-bone character shadow (head, torso, arms, legs) onto the ground in 1st-person
				# without rendering upper-body triangles into the 1st-person camera viewport!
				var shadow_mi := MeshInstance3D.new()
				shadow_mi.name = "FPShadowCasterBody"
				shadow_mi.mesh = mi.mesh
				shadow_mi.skin = mi.skin
				shadow_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
				shadow_mi.visible = false
				mi.get_parent().add_child(shadow_mi)
				shadow_mi.skeleton = NodePath("..")

		if skel != null:
			var bone_map: PackedInt32Array = _build_bone_map(skel)
			root.set_meta("bone_map", bone_map)
			# Immediately pose all 65 bones (including fingers) in Pistol_Idle_Loop on creation!
			_apply_base_65_pose(skel, bone_map)
			_sample_mocap_clip_to_skeleton(skel, bone_map, "Pistol_Idle_Loop", 0.0, true)

			# -----------------------------------------------------------------
			# 1. HEAD BONE ATTACHMENT ("Head") — 12 Bespoke Helmets, Masks & Hair
			# -----------------------------------------------------------------
			var head_att := _create_bone_att(skel, "HeadBoneAttachment", "Head")
			var neck_pivot := Node3D.new()
			neck_pivot.name = "NeckPivot"
			neck_pivot.position = Vector3(0.0, 0.11, 0.01)
			head_att.add_child(neck_pivot)

			_add_Legend_headgear_gen5(neck_pivot, lid, mat_prim, mat_sec, mat_under, mat_dark, mat_metal, mat_visor, mat_glow, mat_plasma)

			# -----------------------------------------------------------------
			# 2. CHEST / BACK BONE ATTACHMENT ("spine_03") — Armor, Wings & Drones
			# -----------------------------------------------------------------
			var chest_att := _create_bone_att(skel, "ChestBoneAttachment", "spine_03")
			var chest_piv := Node3D.new()
			chest_piv.name = "ChestPivot"
			chest_piv.position = Vector3(0.0, 0.085, 0.0)
			chest_att.add_child(chest_piv)
			_add_Legend_chestgear_gen5(chest_piv, lid, mat_prim, mat_sec, mat_under, mat_dark, mat_metal, mat_visor, mat_glow, mat_plasma)

			for side_s in [-1.0, 1.0]:
				var j_nozzle := _add_cyl(chest_piv, 0.032, 0.044, 0.11, Vector3(side_s * 0.10, -0.14, -0.15), mat_metal, Vector3(0.35, 0, side_s * 0.18), 10)
				var j_flame := _add_cyl(j_nozzle, 0.028, 0.004, 0.22, Vector3(0, -0.15, 0), mat_glow, Vector3.ZERO, 8, "JumpkitJetL" if side_s < 0.0 else "JumpkitJetR")
				j_flame.visible = false

			# Unified 3D Back Holster Root
			var back_holster := Node3D.new()
			back_holster.name = "BackHolsterRoot"
			back_holster.position = Vector3(0.02, 0.04, -0.16)
			back_holster.rotation = Vector3(0.0, PI * 0.5, 0.68)
			back_holster.scale = Vector3(0.76, 0.76, 0.76)
			back_holster.visible = false
			chest_piv.add_child(back_holster)
			var holstered_wep := WeaponMeshBuilder.create_third_person_weapon_mesh(wep_data)
			back_holster.add_child(holstered_wep)

			# -----------------------------------------------------------------
			# 3. PELVIS / WAIST BONE ATTACHMENT ("pelvis") — Coats, Kilts & Belts
			# -----------------------------------------------------------------
			var pelvis_att := _create_bone_att(skel, "PelvisBoneAttachment", "pelvis")
			_add_Legend_pelvis_gear_gen5(pelvis_att, lid, mat_prim, mat_sec, mat_under, mat_dark, mat_metal, mat_glow, mat_plasma)

			# -----------------------------------------------------------------
			# 4. SHOULDER / UPPER-ARM BONE ATTACHMENTS ("upperarm_l", "upperarm_r")
			# -----------------------------------------------------------------
			var uarm_l := _create_bone_att(skel, "LeftUpperArmAttachment", "upperarm_l")
			var uarm_r := _create_bone_att(skel, "RightUpperArmAttachment", "upperarm_r")
			_add_Legend_upperarm_gear_gen5(uarm_l, uarm_r, lid, mat_prim, mat_sec, mat_under, mat_dark, mat_metal, mat_glow, mat_plasma)

			# -----------------------------------------------------------------
			# 5. FOREARM BONE ATTACHMENTS ("lowerarm_l", "lowerarm_r") — Visible in 1P & 3P!
			# -----------------------------------------------------------------
			var larm_l := _create_bone_att(skel, "LeftLowerArmAttachment", "lowerarm_l")
			var larm_r := _create_bone_att(skel, "RightLowerArmAttachment", "lowerarm_r")
			_add_Legend_forearm_gear_gen5(larm_l, larm_r, lid, mat_prim, mat_sec, mat_under, mat_dark, mat_metal, mat_glow, mat_plasma)

			# -----------------------------------------------------------------
			# 6. THIGH & CALF BONE ATTACHMENTS ("thigh_l/r", "calf_l/r") — Boots, Cargo Pants & Prosthetics
			# -----------------------------------------------------------------
			var thigh_l := _create_bone_att(skel, "LeftThighAttachment", "thigh_l")
			var thigh_r := _create_bone_att(skel, "RightThighAttachment", "thigh_r")
			var calf_l := _create_bone_att(skel, "LeftCalfAttachment", "calf_l")
			var calf_r := _create_bone_att(skel, "RightCalfAttachment", "calf_r")
			_add_Legend_leg_gear_gen5(thigh_l, thigh_r, calf_l, calf_r, lid, mat_prim, mat_sec, mat_under, mat_dark, mat_metal, mat_glow, mat_plasma)

			# -----------------------------------------------------------------
			# 7. RIGHT & LEFT HAND BONE ATTACHMENTS ("hand_r", "hand_l") — Weapons & Heirlooms
			# -----------------------------------------------------------------
			var rhand_att := _create_bone_att(skel, "RightHandBoneAttachment", "hand_r")
			var held_wep_root := Node3D.new()
			held_wep_root.name = "HeldWeaponRoot"
			held_wep_root.position = Vector3(0.0, 0.08, 0.02)
			held_wep_root.rotation = Vector3(PI * 0.5, 0.0, 0.0)
			held_wep_root.scale = Vector3(0.84, 0.84, 0.84)
			rhand_att.add_child(held_wep_root)
			var tp_wep := WeaponMeshBuilder.create_third_person_weapon_mesh(wep_data)
			held_wep_root.add_child(tp_wep)

			var held_hl_root := Node3D.new()
			held_hl_root.name = "HeldHeirloomRoot"
			held_hl_root.visible = false
			rhand_att.add_child(held_hl_root)
			if lid == "pathfinder":
				_build_tp_boxing_glove(held_hl_root, false, h_col)
			else:
				held_hl_root.position = Vector3(0.0, 0.08, 0.02)
				held_hl_root.rotation = Vector3(0.0, 0.0, -PI * 0.5)
				var tp_hl := WeaponMeshBuilder.create_third_person_heirloom_mesh(legend_data)
				held_hl_root.add_child(tp_hl)

			var lhand_att := _create_bone_att(skel, "LeftHandBoneAttachment", "hand_l")
			var held_left_hl := Node3D.new()
			held_left_hl.name = "HeldLeftHeirloomRoot"
			held_left_hl.visible = false
			lhand_att.add_child(held_left_hl)
			if lid == "pathfinder":
				_build_tp_boxing_glove(held_left_hl, true, h_col)
			elif lid == "lifeline" or lid == "ash":
				held_left_hl.position = Vector3(0.0, 0.08, 0.02)
				held_left_hl.rotation = Vector3(0.0, 0.0, PI * 0.5)
				var tp_l_hl := WeaponMeshBuilder.create_third_person_heirloom_mesh(legend_data)
				held_left_hl.add_child(tp_l_hl)

			var heal_prop := Node3D.new()
			heal_prop.name = "HealPropRoot"
			heal_prop.position = Vector3(0.0, 0.08, 0.03)
			heal_prop.visible = false
			lhand_att.add_child(heal_prop)
			_add_cyl(heal_prop, 0.052, 0.052, 0.18, Vector3.ZERO, mat_dark, Vector3.ZERO, 12, "TP_BatteryBody")
			_add_cyl(heal_prop, 0.045, 0.045, 0.11, Vector3.ZERO, mat_glow, Vector3.ZERO, 12, "TP_BatteryCore")

	return root


static func _add_Legend_headgear_gen5(neck_pivot: Node3D, lid: String, mat_prim: Material, mat_sec: Material, mat_under: Material, mat_dark: Material, mat_metal: Material, mat_visor: Material, mat_glow: Material, mat_plasma: Material) -> void:
	match lid:
		"bloodhound":
			# Wide-Brim Nordic Tracker Helmet + Red Samurai Crest + Plague Respirator Beak + Glowing Red Eyes
			_add_cyl(neck_pivot, 0.11, 0.19, 0.055, Vector3(0, 0.085, 0.0), mat_prim, Vector3.ZERO, 16, "BH_Brim")
			_add_sphere(neck_pivot, 0.11, Vector3(0, 0.10, 0.0), mat_dark, "BH_Dome", Vector3(1.05, 0.85, 1.08))
			_add_box(neck_pivot, Vector3(0.28, 0.038, 0.04), Vector3(0, 0.135, 0.03), mat_sec, Vector3.ZERO, "BH_HornBar")
			_add_box(neck_pivot, Vector3(0.035, 0.09, 0.03), Vector3(-0.13, 0.16, 0.03), mat_sec, Vector3(0, 0, 0.35))
			_add_box(neck_pivot, Vector3(0.035, 0.09, 0.03), Vector3(0.13, 0.16, 0.03), mat_sec, Vector3(0, 0, -0.35))
			_add_cyl(neck_pivot, 0.022, 0.068, 0.13, Vector3(0, -0.015, 0.135), mat_dark, Vector3(PI * 0.52, 0, 0), 10, "PlagueBeak")
			_add_box(neck_pivot, Vector3(0.13, 0.032, 0.04), Vector3(0, 0.03, 0.105), mat_visor)
		"pathfinder":
			# Iconic Blue MRVN Cyclops Camera Head (Completely encapsulates human head!)
			_add_box(neck_pivot, Vector3(0.20, 0.21, 0.23), Vector3(0, 0.025, 0.015), mat_prim, Vector3.ZERO, "MRVNHeadChassis")
			_add_box(neck_pivot, Vector3(0.16, 0.17, 0.24), Vector3(0, 0.025, 0.015), mat_sec)
			_add_cyl(neck_pivot, 0.068, 0.068, 0.05, Vector3(0, 0.025, 0.125), mat_dark, Vector3(PI * 0.5, 0, 0), 18, "MRVNEyeRing")
			_add_cyl(neck_pivot, 0.054, 0.054, 0.055, Vector3(0, 0.025, 0.128), mat_visor, Vector3(PI * 0.5, 0, 0), 18, "MRVNEyeLens")
			_add_cyl(neck_pivot, 0.010, 0.014, 0.13, Vector3(0.11, 0.12, 0.0), mat_metal, Vector3(0, 0, -0.25), 8)
			_add_cyl(neck_pivot, 0.010, 0.014, 0.13, Vector3(-0.11, 0.12, 0.0), mat_metal, Vector3(0, 0, 0.25), 8)
		"wraith":
			# Thick Coiled Dark-Indigo Void Scarf + Swept Ninja Hair Bun + Glowing Violet Void Eyes
			_add_cyl(neck_pivot, 0.135, 0.155, 0.10, Vector3(0, -0.065, 0.015), mat_dark, Vector3.ZERO, 16, "VoidScarf")
			_add_sphere(neck_pivot, 0.108, Vector3(0, 0.055, -0.015), mat_dark, "WraithHairCap", Vector3(1.02, 1.0, 1.08))
			_add_sphere(neck_pivot, 0.068, Vector3(0, 0.105, -0.105), mat_dark, "WraithHairBun")
			_add_box(neck_pivot, Vector3(0.16, 0.04, 0.04), Vector3(0, 0.05, 0.095), mat_dark, Vector3(0, 0, -0.18), "WraithBangs")
			_add_box(neck_pivot, Vector3(0.12, 0.026, 0.03), Vector3(0, 0.022, 0.105), mat_visor, Vector3.ZERO, "VoidEyes")
		"octane":
			# Dual Round Neon-Green Bug-Eye Goggles + Spiked respirator mask + Head Hood
			_add_sphere(neck_pivot, 0.108, Vector3(0, 0.04, -0.005), mat_dark, "OctaneHood", Vector3(1.02, 1.04, 1.05))
			_add_cyl(neck_pivot, 0.048, 0.048, 0.045, Vector3(-0.048, 0.035, 0.105), mat_sec, Vector3(PI * 0.5, 0, 0), 14, "GoggleL")
			_add_cyl(neck_pivot, 0.048, 0.048, 0.045, Vector3(0.048, 0.035, 0.105), mat_sec, Vector3(PI * 0.5, 0, 0), 14, "GoggleR")
			_add_cyl(neck_pivot, 0.038, 0.038, 0.050, Vector3(-0.048, 0.035, 0.107), mat_visor, Vector3(PI * 0.5, 0, 0), 14)
			_add_cyl(neck_pivot, 0.038, 0.038, 0.050, Vector3(0.048, 0.035, 0.107), mat_visor, Vector3(PI * 0.5, 0, 0), 14)
			_add_box(neck_pivot, Vector3(0.135, 0.070, 0.08), Vector3(0, -0.032, 0.095), mat_dark, Vector3.ZERO, "RespiratorMask")
			_add_box(neck_pivot, Vector3(0.10, 0.022, 0.02), Vector3(0, -0.032, 0.138), mat_visor, Vector3.ZERO, "MaskTeeth")
		"lifeline":
			# White/Teal Rescue Headband + Signature Twin Large Crimson-Pink Hair Puffs
			_add_cyl(neck_pivot, 0.112, 0.112, 0.038, Vector3(0, 0.065, 0.005), mat_sec, Vector3.ZERO, 16, "MedicHeadband")
			_add_sphere(neck_pivot, 0.078, Vector3(-0.128, 0.085, -0.02), mat_prim, "LeftBun", Vector3(1.0, 1.08, 1.0))
			_add_sphere(neck_pivot, 0.078, Vector3(0.128, 0.085, -0.02), mat_prim, "RightBun", Vector3(1.0, 1.08, 1.0))
			_add_box(neck_pivot, Vector3(0.125, 0.028, 0.03), Vector3(0, 0.022, 0.102), mat_visor)
		"gibraltar":
			# Massive Juggernaut Ballistic Helmet + Tribal White/Orange Crest + Thick Armored Collar
			_add_cyl(neck_pivot, 0.16, 0.19, 0.09, Vector3(0, -0.065, 0.0), mat_prim, Vector3.ZERO, 16, "GibbyCollar")
			_add_sphere(neck_pivot, 0.132, Vector3(0, 0.05, 0.0), mat_prim, "GibbyHelm", Vector3(1.12, 1.02, 1.15))
			_add_box(neck_pivot, Vector3(0.055, 0.075, 0.23), Vector3(0, 0.125, 0.0), mat_sec, Vector3.ZERO, "GibbyCrest")
			_add_box(neck_pivot, Vector3(0.15, 0.036, 0.05), Vector3(0, 0.025, 0.112), mat_visor)
		"valkyrie":
			# Enclosed Northstar Viper Flight Helmet + Swept Side Wings + Full Cyan Visor Dome
			_add_sphere(neck_pivot, 0.128, Vector3(0, 0.035, 0.01), mat_prim, "ViperHelm", Vector3(1.06, 1.06, 1.18))
			_add_sphere(neck_pivot, 0.112, Vector3(0, 0.025, 0.045), mat_visor, "ViperVisorDome", Vector3(0.96, 0.78, 1.0))
			_add_box(neck_pivot, Vector3(0.022, 0.085, 0.18), Vector3(-0.118, 0.065, -0.04), mat_sec, Vector3(0.28, -0.22, 0))
			_add_box(neck_pivot, Vector3(0.022, 0.085, 0.18), Vector3(0.118, 0.065, -0.04), mat_sec, Vector3(0.28, 0.22, 0))
		"ash":
			# White Porcelain Simulacrum Faceplate + Dark Draped Ronin Hood with Gold/Cyan Trim
			_add_sphere(neck_pivot, 0.138, Vector3(0, 0.035, -0.015), mat_prim, "AshHood", Vector3(1.10, 1.16, 1.18))
			_add_cyl(neck_pivot, 0.13, 0.16, 0.09, Vector3(0, -0.06, -0.01), mat_prim, Vector3.ZERO, 14, "AshCowl")
			_add_box(neck_pivot, Vector3(0.135, 0.165, 0.045), Vector3(0, 0.022, 0.092), mat_under, Vector3.ZERO, "PorcelainMask")
			_add_box(neck_pivot, Vector3(0.115, 0.024, 0.05), Vector3(0, 0.032, 0.102), mat_visor, Vector3.ZERO, "AshEyes")
		"caustic":
			# Slicked Hair + Dual-Filter Yellow/Green Nox Gas Mask + Glowing Green Goggles
			_add_sphere(neck_pivot, 0.112, Vector3(0, 0.06, -0.01), mat_dark, "CausticHair", Vector3(1.02, 0.95, 1.08))
			_add_box(neck_pivot, Vector3(0.135, 0.075, 0.085), Vector3(0, -0.03, 0.09), mat_dark, Vector3.ZERO, "GasMaskBody")
			_add_cyl(neck_pivot, 0.042, 0.046, 0.065, Vector3(-0.062, -0.035, 0.12), mat_sec, Vector3(PI * 0.4, -0.42, 0), 12, "NoxFilterL")
			_add_cyl(neck_pivot, 0.042, 0.046, 0.065, Vector3(0.062, -0.035, 0.12), mat_sec, Vector3(PI * 0.4, 0.42, 0), 12, "NoxFilterR")
			_add_box(neck_pivot, Vector3(0.135, 0.034, 0.045), Vector3(0, 0.028, 0.105), mat_visor)
		"horizon":
			# Swept Orange/Red Gravity Hair Crest + White EVA Space-Helmet Collar Ring + Blue Visor
			_add_cyl(neck_pivot, 0.145, 0.16, 0.055, Vector3(0, -0.065, 0.0), mat_under, Vector3.ZERO, 16, "SpaceCollar")
			_add_sphere(neck_pivot, 0.112, Vector3(0, 0.065, 0.0), mat_sec, "HorizonHair", Vector3(1.02, 1.08, 1.06))
			_add_box(neck_pivot, Vector3(0.065, 0.095, 0.15), Vector3(0, 0.125, 0.03), mat_sec, Vector3(-0.25, 0, 0), "HairPompadour")
			_add_box(neck_pivot, Vector3(0.135, 0.034, 0.045), Vector3(0, 0.025, 0.105), mat_visor)
		"mirage":
			# Yellow Bandana + Dark Curls + Uplifted Glowing Gold Holo-Goggles on Forehead
			_add_cyl(neck_pivot, 0.114, 0.114, 0.036, Vector3(0, 0.06, 0.005), mat_prim, Vector3.ZERO, 16, "MirageBandana")
			_add_sphere(neck_pivot, 0.108, Vector3(0, 0.09, -0.01), mat_dark, "MirageCurls", Vector3(1.04, 0.88, 1.04))
			_add_cyl(neck_pivot, 0.042, 0.042, 0.04, Vector3(-0.046, 0.075, 0.105), mat_plasma, Vector3(PI * 0.5, 0, 0), 12)
			_add_cyl(neck_pivot, 0.042, 0.042, 0.04, Vector3(0.046, 0.075, 0.105), mat_plasma, Vector3(PI * 0.5, 0, 0), 12)
			_add_box(neck_pivot, Vector3(0.13, 0.030, 0.04), Vector3(0, 0.02, 0.102), mat_visor)
		_:
			# Bangalore High-Top Military Frohawk Curls + IMC Tactical Earpiece & Amber Visor
			_add_box(neck_pivot, Vector3(0.095, 0.095, 0.18), Vector3(0, 0.115, 0.01), mat_dark, Vector3(-0.1, 0, 0), "BangaloreHair")
			_add_cyl(neck_pivot, 0.044, 0.044, 0.032, Vector3(-0.11, 0.02, 0.0), mat_sec, Vector3(0, 0, PI * 0.5), 10)
			_add_cyl(neck_pivot, 0.044, 0.044, 0.032, Vector3(0.11, 0.02, 0.0), mat_sec, Vector3(0, 0, PI * 0.5), 10)
			_add_box(neck_pivot, Vector3(0.135, 0.034, 0.045), Vector3(0, 0.025, 0.105), mat_visor)


static func _add_Legend_chestgear_gen5(chest_att: Node3D, lid: String, mat_prim: Material, mat_sec: Material, mat_under: Material, mat_dark: Material, mat_metal: Material, _mat_visor: Material, mat_glow: Material, mat_plasma: Material) -> void:
	match lid:
		"pathfinder":
			# Heavy Robot Chest Chassis + Glowing Cyan LCD Smiley Screen + Twin Shoulder Zipline Winches
			_add_box(chest_att, Vector3(0.31, 0.28, 0.16), Vector3(0, 0.02, 0.02), mat_prim, Vector3.ZERO, "RobotTorsoBox")
			_add_box(chest_att, Vector3(0.19, 0.15, 0.03), Vector3(0, 0.03, 0.115), mat_dark)
			_add_box(chest_att, Vector3(0.16, 0.12, 0.035), Vector3(0, 0.03, 0.120), mat_glow, Vector3.ZERO, "PathfinderChestScreen")
			_add_cyl(chest_att, 0.065, 0.065, 0.09, Vector3(-0.19, 0.15, -0.06), mat_metal, Vector3(0, 0, PI * 0.5), 14, "ZipSpoolL")
			_add_cyl(chest_att, 0.065, 0.065, 0.09, Vector3(0.19, 0.15, -0.06), mat_metal, Vector3(0, 0, PI * 0.5), 14, "ZipSpoolR")
		"valkyrie":
			# Flight Harness + Huge Swept Northstar VTOL Jetpack Wings & Twin Shoulder Missile Pods
			_add_box(chest_att, Vector3(0.27, 0.22, 0.08), Vector3(0, 0.03, 0.09), mat_prim, Vector3.ZERO, "ValkFlightVest")
			_add_box(chest_att, Vector3(0.24, 0.30, 0.13), Vector3(0, 0.04, -0.14), mat_dark, Vector3.ZERO, "VTOLPack")
			# Twin Swept Main Wings
			_add_box(chest_att, Vector3(0.56, 0.11, 0.032), Vector3(-0.36, 0.16, -0.17), mat_prim, Vector3(0, -0.22, 0.38), "ValkWingL")
			_add_box(chest_att, Vector3(0.56, 0.11, 0.032), Vector3(0.36, 0.16, -0.17), mat_prim, Vector3(0, 0.22, -0.38), "ValkWingR")
			# Secondary Lower Aero Fins
			_add_box(chest_att, Vector3(0.38, 0.075, 0.025), Vector3(-0.26, -0.02, -0.16), mat_sec, Vector3(0, -0.15, -0.28), "ValkSubWingL")
			_add_box(chest_att, Vector3(0.38, 0.075, 0.025), Vector3(0.26, -0.02, -0.16), mat_sec, Vector3(0, 0.15, 0.28), "ValkSubWingR")
			# Shoulder Missile Pods
			_add_box(chest_att, Vector3(0.11, 0.12, 0.16), Vector3(-0.18, 0.22, -0.10), mat_sec, Vector3(-0.2, 0, 0), "MissilePodL")
			_add_box(chest_att, Vector3(0.11, 0.12, 0.16), Vector3(0.18, 0.22, -0.10), mat_sec, Vector3(-0.2, 0, 0), "MissilePodR")
		"gibraltar":
			# Massive Layered Bomb-Suit Juggernaut Cuirass + Giant Glowing Back Protection Dome Shield Disc
			_add_box(chest_att, Vector3(0.36, 0.30, 0.14), Vector3(0, 0.02, 0.07), mat_prim, Vector3.ZERO, "GibbyCuirass")
			_add_box(chest_att, Vector3(0.26, 0.22, 0.06), Vector3(0, 0.03, 0.135), mat_sec, Vector3.ZERO, "GibbyFrontPlate")
			_add_cyl(chest_att, 0.23, 0.23, 0.07, Vector3(0, 0.05, -0.15), mat_sec, Vector3(PI * 0.5, 0, 0), 18, "GibbyBackDome")
			_add_cyl(chest_att, 0.16, 0.16, 0.08, Vector3(0, 0.05, -0.155), mat_glow, Vector3(PI * 0.5, 0, 0), 16, "GibbyBackCore")
		"caustic":
			# Bright Yellow Hazmat Chest Apron + Three Pressurized Nox Gas Cylinders on Back
			_add_box(chest_att, Vector3(0.32, 0.28, 0.11), Vector3(0, 0.01, 0.07), mat_sec, Vector3.ZERO, "CausticHazmatChest")
			_add_cyl(chest_att, 0.045, 0.045, 0.06, Vector3(-0.09, 0.08, 0.13), mat_dark, Vector3(PI * 0.5, 0, 0), 10)
			_add_cyl(chest_att, 0.045, 0.045, 0.06, Vector3(0.09, 0.08, 0.13), mat_dark, Vector3(PI * 0.5, 0, 0), 10)
			_add_cyl(chest_att, 0.058, 0.058, 0.34, Vector3(-0.10, 0.03, -0.15), mat_sec, Vector3.ZERO, 14, "NoxTankL")
			_add_cyl(chest_att, 0.058, 0.058, 0.34, Vector3(0.10, 0.03, -0.15), mat_sec, Vector3.ZERO, 14, "NoxTankR")
			_add_cyl(chest_att, 0.045, 0.045, 0.28, Vector3(0.0, 0.05, -0.19), mat_plasma, Vector3.ZERO, 12, "NoxTankCenter")
		"lifeline":
			# White/Magenta Combat Medic Rescue Vest + Docked D.O.C. Healing Drone on Back
			_add_box(chest_att, Vector3(0.27, 0.22, 0.09), Vector3(0, 0.03, 0.07), mat_under, Vector3.ZERO, "MedicVest")
			_add_box(chest_att, Vector3(0.09, 0.09, 0.02), Vector3(0, 0.05, 0.12), mat_prim, Vector3.ZERO, "MedicCross")
			_add_cyl(chest_att, 0.15, 0.15, 0.06, Vector3(0, 0.05, -0.14), mat_metal, Vector3(PI * 0.5, 0, 0), 16, "DOCDroneBody")
			_add_sphere(chest_att, 0.065, Vector3(0, 0.05, -0.175), mat_plasma, "DOCDroneCore")
		"octane":
			# Cropped Green Stunt Vest + Twin Sleek Stim Dialysis Cylinders on Back
			_add_box(chest_att, Vector3(0.26, 0.20, 0.08), Vector3(0, 0.01, 0.065), mat_prim, Vector3.ZERO, "StuntVest")
			_add_cyl(chest_att, 0.032, 0.032, 0.18, Vector3(-0.075, -0.02, -0.13), mat_dark, Vector3(0, 0, 0.18), 12, "StimTankL")
			_add_cyl(chest_att, 0.032, 0.032, 0.18, Vector3(0.075, -0.02, -0.13), mat_dark, Vector3(0, 0, -0.18), 12, "StimTankR")
			_add_cyl(chest_att, 0.024, 0.024, 0.10, Vector3(-0.075, -0.02, -0.135), mat_plasma, Vector3(0, 0, 0.18), 10)
			_add_cyl(chest_att, 0.024, 0.024, 0.10, Vector3(0.075, -0.02, -0.135), mat_plasma, Vector3(0, 0, -0.18), 10)
		"bloodhound":
			# Layered Bronze Hunter Mantle + Fur Collar + Sonar Radar Pack on Back
			_add_box(chest_att, Vector3(0.31, 0.26, 0.11), Vector3(0, 0.02, 0.065), mat_prim, Vector3.ZERO, "HunterCuirass")
			_add_cyl(chest_att, 0.16, 0.19, 0.08, Vector3(0, 0.14, 0.0), mat_dark, Vector3.ZERO, 14, "FurCollar")
			_add_box(chest_att, Vector3(0.22, 0.26, 0.10), Vector3(0, 0.03, -0.14), mat_dark, Vector3.ZERO, "SonarPack")
			_add_cyl(chest_att, 0.012, 0.012, 0.28, Vector3(-0.09, 0.22, -0.15), mat_metal, Vector3.ZERO, 8, "SonarAntenna")
		"bangalore":
			# Heavy IMC Ballistic Flak Vest with Triple Mag Pouches + Shoulder-Mounted Smoke Launcher!
			_add_box(chest_att, Vector3(0.29, 0.26, 0.11), Vector3(0, 0.02, 0.07), mat_prim, Vector3.ZERO, "IMCFlakVest")
			for m_i in [-1, 0, 1]:
				_add_box(chest_att, Vector3(0.055, 0.09, 0.04), Vector3(float(m_i) * 0.075, -0.02, 0.135), mat_sec)
			# Iconic Over-the-Shoulder 3-Barrel Smoke Launcher on Left Back/Shoulder
			_add_box(chest_att, Vector3(0.11, 0.24, 0.12), Vector3(0.13, 0.16, -0.13), mat_dark, Vector3(0.45, 0, -0.15), "SmokeLauncher")
			_add_cyl(chest_att, 0.028, 0.028, 0.16, Vector3(0.13, 0.25, -0.07), mat_metal, Vector3(0.45, 0, -0.15), 10)
		"ash":
			# Sleek Cybernetic Corset + Diagonal Phase-Breach Katana Scabbard on Back
			_add_box(chest_att, Vector3(0.25, 0.24, 0.09), Vector3(0, 0.02, 0.06), mat_prim, Vector3.ZERO, "AshChestPlate")
			_add_box(chest_att, Vector3(0.08, 0.18, 0.02), Vector3(0, 0.03, 0.11), mat_sec, Vector3.ZERO, "AshRibCore")
			_add_box(chest_att, Vector3(0.04, 0.72, 0.055), Vector3(0.0, 0.06, -0.15), mat_dark, Vector3(0, 0, 0.58), "AshSwordSheath")
			_add_box(chest_att, Vector3(0.045, 0.70, 0.02), Vector3(0.0, 0.06, -0.175), mat_sec, Vector3(0, 0, 0.58))
		"horizon":
			# White/Blue EVA Astronaut Chest + N.E.W.T. Black-Hole Singularity Backpack
			_add_box(chest_att, Vector3(0.28, 0.25, 0.10), Vector3(0, 0.02, 0.065), mat_under, Vector3.ZERO, "EVAChest")
			_add_box(chest_att, Vector3(0.14, 0.12, 0.03), Vector3(0, 0.04, 0.12), mat_prim, Vector3.ZERO, "EVAConsole")
			_add_cyl(chest_att, 0.14, 0.14, 0.09, Vector3(0, 0.05, -0.15), mat_under, Vector3(PI * 0.5, 0, 0), 16, "NewtPack")
			_add_cyl(chest_att, 0.095, 0.095, 0.10, Vector3(0, 0.05, -0.16), mat_glow, Vector3(PI * 0.5, 0, 0), 16, "NewtSingularity")
		"wraith":
			# Voidrunner Cropped Jacket + Diagonal Silver Cross-Strap + Glowing Violet Phase Reactor
			_add_box(chest_att, Vector3(0.26, 0.22, 0.09), Vector3(0, 0.03, 0.06), mat_prim, Vector3.ZERO, "VoidJacket")
			_add_box(chest_att, Vector3(0.055, 0.28, 0.11), Vector3(0, 0.02, 0.065), mat_metal, Vector3(0, 0, 0.52), "CrossBelt")
			_add_cyl(chest_att, 0.085, 0.085, 0.07, Vector3(0, 0.04, -0.13), mat_plasma, Vector3(PI * 0.5, 0, 0), 14, "PhaseReactor")
		"mirage":
			# Quilted Gold/Dark Stunt Jacket + Glowing Cyan Holo-Emitter Discs on Chest & Back
			_add_box(chest_att, Vector3(0.29, 0.25, 0.10), Vector3(0, 0.02, 0.065), mat_prim, Vector3.ZERO, "MirageJacket")
			_add_cyl(chest_att, 0.042, 0.042, 0.025, Vector3(-0.085, 0.06, 0.12), mat_glow, Vector3(PI * 0.5, 0, 0), 12)
			_add_cyl(chest_att, 0.042, 0.042, 0.025, Vector3(0.085, 0.06, 0.12), mat_glow, Vector3(PI * 0.5, 0, 0), 12)
			_add_box(chest_att, Vector3(0.20, 0.24, 0.08), Vector3(0, 0.03, -0.13), mat_dark, Vector3.ZERO, "HoloPack")


static func _add_Legend_pelvis_gear_gen5(pelvis_att: Node3D, lid: String, mat_prim: Material, mat_sec: Material, _mat_under: Material, mat_dark: Material, mat_metal: Material, mat_glow: Material, mat_plasma: Material) -> void:
	# Tactical Utility Belt at Waist (y = 0.02)
	_add_box(pelvis_att, Vector3(0.29, 0.065, 0.22), Vector3(0, 0.01, 0.0), mat_dark, Vector3.ZERO, "WaistBelt")
	_add_box(pelvis_att, Vector3(0.07, 0.075, 0.03), Vector3(0, 0.01, 0.115), mat_metal, Vector3.ZERO, "BeltBuckle")

	match lid:
		"bloodhound":
			# Long Split Hunter Tunic Coat-Tails / Kama Skirt hanging down (-Y) around hips!
			_add_box(pelvis_att, Vector3(0.32, 0.28, 0.04), Vector3(0, -0.14, -0.11), mat_prim, Vector3(-0.12, 0, 0), "HunterBackCoat")
			_add_box(pelvis_att, Vector3(0.04, 0.26, 0.22), Vector3(-0.155, -0.13, 0.0), mat_prim, Vector3(0, 0, -0.12), "HunterSideCoatR")
			_add_box(pelvis_att, Vector3(0.04, 0.26, 0.22), Vector3(0.155, -0.13, 0.0), mat_prim, Vector3(0, 0, 0.12), "HunterSideCoatL")
		"bangalore":
			# Pleated Crimson/Amber Tactical Battle-Skirt around Hips & Upper Thighs!
			_add_box(pelvis_att, Vector3(0.33, 0.27, 0.045), Vector3(0, -0.14, -0.11), mat_prim, Vector3(-0.10, 0, 0), "BattleSkirtBack")
			_add_box(pelvis_att, Vector3(0.045, 0.26, 0.23), Vector3(-0.16, -0.13, 0.0), mat_prim, Vector3(0, 0, -0.10), "BattleSkirtR")
			_add_box(pelvis_att, Vector3(0.045, 0.26, 0.23), Vector3(0.16, -0.13, 0.0), mat_prim, Vector3(0, 0, 0.10), "BattleSkirtL")
			_add_box(pelvis_att, Vector3(0.14, 0.22, 0.035), Vector3(0, -0.12, 0.115), mat_sec, Vector3(0.08, 0, 0), "BattleSkirtFront")
		"ash":
			# Long Flowing Dark/Cyan Ronin Kama Split Coat-Tails
			_add_box(pelvis_att, Vector3(0.13, 0.34, 0.035), Vector3(-0.085, -0.17, -0.11), mat_prim, Vector3(-0.14, 0, -0.08), "AshTailR")
			_add_box(pelvis_att, Vector3(0.13, 0.34, 0.035), Vector3(0.085, -0.17, -0.11), mat_prim, Vector3(-0.14, 0, 0.08), "AshTailL")
			_add_box(pelvis_att, Vector3(0.035, 0.28, 0.20), Vector3(-0.15, -0.14, 0.0), mat_sec, Vector3(0, 0, -0.12))
			_add_box(pelvis_att, Vector3(0.035, 0.28, 0.20), Vector3(0.15, -0.14, 0.0), mat_sec, Vector3(0, 0, 0.12))
		"caustic":
			# Heavy Yellow Rubberized Hazmat Lab Apron Draping Front & Back
			_add_box(pelvis_att, Vector3(0.28, 0.26, 0.04), Vector3(0, -0.13, 0.115), mat_sec, Vector3(0.10, 0, 0), "HazmatFrontApron")
			_add_box(pelvis_att, Vector3(0.32, 0.28, 0.04), Vector3(0, -0.14, -0.115), mat_sec, Vector3(-0.10, 0, 0), "HazmatBackApron")
		"gibraltar":
			# Heavy Juggernaut Armored Hip & Groin Ballistic Tassets
			_add_box(pelvis_att, Vector3(0.20, 0.22, 0.06), Vector3(0, -0.11, 0.125), mat_prim, Vector3(0.08, 0, 0), "GibbyGroinPlate")
			_add_box(pelvis_att, Vector3(0.06, 0.22, 0.24), Vector3(-0.175, -0.10, 0.0), mat_sec, Vector3(0, 0, -0.15), "GibbyTassetR")
			_add_box(pelvis_att, Vector3(0.06, 0.22, 0.24), Vector3(0.175, -0.10, 0.0), mat_sec, Vector3(0, 0, 0.15), "GibbyTassetL")
		"wraith":
			# Asymmetric Flowing Ninja Sash + Kunai Holster Pouch
			_add_box(pelvis_att, Vector3(0.04, 0.26, 0.18), Vector3(0.15, -0.12, -0.02), mat_prim, Vector3(0, 0, 0.16), "WraithSash")
			_add_box(pelvis_att, Vector3(0.06, 0.12, 0.08), Vector3(-0.155, -0.04, 0.04), mat_plasma, Vector3(0, 0, -0.2), "KunaiPouch")
		"octane":
			# Compact Dark-Carbon Jump-Pad Pack on Rear Waist
			_add_cyl(pelvis_att, 0.075, 0.075, 0.035, Vector3(0, 0.0, -0.115), mat_dark, Vector3(PI * 0.5, 0, 0), 14, "WaistJumpPad")
			_add_cyl(pelvis_att, 0.045, 0.045, 0.038, Vector3(0, 0.0, -0.116), mat_sec, Vector3(PI * 0.5, 0, 0), 12)
		"horizon":
			# Padded White EVA Space-Suit Hip Ring + Gravity Lift Discs
			_add_cyl(pelvis_att, 0.165, 0.175, 0.08, Vector3(0, 0.0, 0.0), mat_sec, Vector3.ZERO, 16, "EVAWaistRing")
			_add_cyl(pelvis_att, 0.055, 0.055, 0.03, Vector3(-0.16, -0.02, 0.04), mat_glow, Vector3(0, 0, PI * 0.5), 12)


static func _add_Legend_upperarm_gear_gen5(uarm_l: Node3D, uarm_r: Node3D, lid: String, mat_prim: Material, mat_sec: Material, mat_under: Material, mat_dark: Material, mat_metal: Material, mat_glow: Material, mat_plasma: Material) -> void:
	# Note: in upperarm_l/r local space, +Y runs from shoulder (y=0.0) to elbow (y=0.26)
	match lid:
		"gibraltar":
			# Huge Rounded Juggernaut Bomb-Suit Shoulder Pauldrons
			_add_sphere(uarm_l, 0.115, Vector3(0.03, 0.05, 0.0), mat_prim, "GibbyPauldronL", Vector3(1.15, 1.25, 1.15))
			_add_sphere(uarm_r, 0.115, Vector3(-0.03, 0.05, 0.0), mat_prim, "GibbyPauldronR", Vector3(1.15, 1.25, 1.15))
			_add_box(uarm_l, Vector3(0.04, 0.16, 0.14), Vector3(0.09, 0.07, 0.0), mat_sec)
			_add_box(uarm_r, Vector3(0.04, 0.16, 0.14), Vector3(-0.09, 0.07, 0.0), mat_sec)
		"bloodhound":
			# Layered Samurai-Style Bronze Shoulder Armor Plates
			_add_box(uarm_l, Vector3(0.14, 0.16, 0.15), Vector3(0.03, 0.06, 0.0), mat_prim, Vector3(0, 0, -0.22), "BHPauldronL")
			_add_box(uarm_r, Vector3(0.14, 0.16, 0.15), Vector3(-0.03, 0.06, 0.0), mat_prim, Vector3(0, 0, 0.22), "BHPauldronR")
			_add_box(uarm_l, Vector3(0.15, 0.04, 0.16), Vector3(0.04, 0.12, 0.0), mat_sec)
			_add_box(uarm_r, Vector3(0.15, 0.04, 0.16), Vector3(-0.04, 0.12, 0.0), mat_sec)
		"pathfinder":
			# Cylindrical Mechanical Robot Upper-Arm Struts & Shoulder Ball-Joints
			_add_sphere(uarm_l, 0.078, Vector3(0, 0.02, 0), mat_sec, "RobotShoulderL")
			_add_sphere(uarm_r, 0.078, Vector3(0, 0.02, 0), mat_sec, "RobotShoulderR")
			_add_cyl(uarm_l, 0.058, 0.052, 0.22, Vector3(0, 0.13, 0), mat_prim, Vector3.ZERO, 12, "RobotUpperArmL")
			_add_cyl(uarm_r, 0.058, 0.052, 0.22, Vector3(0, 0.13, 0), mat_prim, Vector3.ZERO, 12, "RobotUpperArmR")
		"mirage":
			# Padded Stunt Sleeves + Signature Glowing Cyan Circular Holo-Emitter Discs!
			_add_cyl(uarm_l, 0.068, 0.060, 0.18, Vector3(0, 0.11, 0), mat_prim, Vector3.ZERO, 14)
			_add_cyl(uarm_r, 0.068, 0.060, 0.18, Vector3(0, 0.11, 0), mat_prim, Vector3.ZERO, 14)
			_add_cyl(uarm_l, 0.042, 0.042, 0.03, Vector3(0.065, 0.08, 0.0), mat_glow, Vector3(0, 0, PI * 0.5), 14, "HoloDiscShoulderL")
			_add_cyl(uarm_r, 0.042, 0.042, 0.03, Vector3(-0.065, 0.08, 0.0), mat_glow, Vector3(0, 0, PI * 0.5), 14, "HoloDiscShoulderR")
		"horizon":
			# Padded White/Orange EVA Astronaut Spacesuit Shoulder Spheres
			_add_sphere(uarm_l, 0.088, Vector3(0.02, 0.06, 0), mat_under, "EVAShoulderL", Vector3(1.1, 1.2, 1.1))
			_add_sphere(uarm_r, 0.088, Vector3(-0.02, 0.06, 0), mat_under, "EVAShoulderR", Vector3(1.1, 1.2, 1.1))
			_add_cyl(uarm_l, 0.066, 0.066, 0.035, Vector3(0, 0.14, 0), mat_sec, Vector3.ZERO, 14)
			_add_cyl(uarm_r, 0.066, 0.066, 0.035, Vector3(0, 0.14, 0), mat_sec, Vector3.ZERO, 14)
		"ash":
			# Angular Cybernetic Shoulder Fins
			_add_box(uarm_l, Vector3(0.035, 0.18, 0.13), Vector3(0.065, 0.05, 0), mat_sec, Vector3(0, 0, -0.35), "AshPauldronL")
			_add_box(uarm_r, Vector3(0.035, 0.18, 0.13), Vector3(-0.065, 0.05, 0), mat_sec, Vector3(0, 0, 0.35), "AshPauldronR")
		"wraith":
			# Asymmetric Silver Left Shoulder Pauldron + Padded Indigo Sleeves
			_add_sphere(uarm_l, 0.082, Vector3(0.02, 0.05, 0), mat_metal, "WraithPauldronL", Vector3(1.1, 1.15, 1.1))
			_add_cyl(uarm_r, 0.060, 0.055, 0.16, Vector3(0, 0.10, 0), mat_dark, Vector3.ZERO, 12)
		"caustic":
			# Heavy Olive/Yellow Hazmat Padded Upper Arms
			_add_cyl(uarm_l, 0.075, 0.068, 0.20, Vector3(0, 0.11, 0), mat_prim, Vector3.ZERO, 14)
			_add_cyl(uarm_r, 0.075, 0.068, 0.20, Vector3(0, 0.11, 0), mat_prim, Vector3.ZERO, 14)
		_:
			# Tactical Shoulder Pads for Valkyrie, Bangalore, Octane, Lifeline
			_add_box(uarm_l, Vector3(0.11, 0.13, 0.12), Vector3(0.02, 0.06, 0), mat_sec)
			_add_box(uarm_r, Vector3(0.11, 0.13, 0.12), Vector3(-0.02, 0.06, 0), mat_sec)


static func _add_Legend_forearm_gear_gen5(larm_l: Node3D, larm_r: Node3D, lid: String, mat_prim: Material, mat_sec: Material, _mat_under: Material, mat_dark: Material, mat_metal: Material, mat_glow: Material, mat_plasma: Material) -> void:
	# Visible in BOTH 1st-Person and 3rd-Person! (+Y runs elbow -> wrist, y = 0.04..0.22)
	match lid:
		"wraith":
			# Wraith Signature Left Forearm Dimensional Void Gauntlet + Glowing Violet Coils!
			_add_cyl(larm_l, 0.054, 0.046, 0.16, Vector3(0, 0.12, 0), mat_dark, Vector3.ZERO, 14, "VoidGauntletL")
			_add_box(larm_l, Vector3(0.04, 0.12, 0.07), Vector3(0.035, 0.13, 0), mat_metal)
			_add_cyl(larm_l, 0.056, 0.056, 0.025, Vector3(0, 0.15, 0), mat_plasma, Vector3.ZERO, 14, "VoidCoil")
			_add_cyl(larm_r, 0.050, 0.044, 0.14, Vector3(0, 0.13, 0), mat_dark, Vector3.ZERO, 12)
		"pathfinder":
			# Pathfinder Left Forearm Grappling Hook Winch & Right Robotic Forearm Strut
			_add_cyl(larm_l, 0.055, 0.048, 0.20, Vector3(0, 0.11, 0), mat_prim, Vector3.ZERO, 12)
			_add_cyl(larm_r, 0.055, 0.048, 0.20, Vector3(0, 0.11, 0), mat_prim, Vector3.ZERO, 12)
			_add_cyl(larm_l, 0.038, 0.038, 0.12, Vector3(0.045, 0.14, 0), mat_metal, Vector3.ZERO, 10, "GrappleLauncher")
			_add_cyl(larm_l, 0.042, 0.042, 0.03, Vector3(0.045, 0.19, 0), mat_glow, Vector3.ZERO, 10)
		"gibraltar":
			# Gibraltar Left Forearm Hard-Light Gun-Shield Projector Emitter + Heavy Arm Guards
			_add_box(larm_l, Vector3(0.11, 0.18, 0.11), Vector3(0, 0.12, 0), mat_prim, Vector3.ZERO, "GibbyBracerL")
			_add_box(larm_r, Vector3(0.10, 0.17, 0.10), Vector3(0, 0.12, 0), mat_prim, Vector3.ZERO, "GibbyBracerR")
			_add_cyl(larm_l, 0.055, 0.055, 0.03, Vector3(0.055, 0.13, 0), mat_glow, Vector3(0, 0, PI * 0.5), 14, "GunShieldEmitter")
		"mirage":
			# Mirage Signature Glowing Cyan Holo-Decoy Emitters on Both Forearms
			_add_cyl(larm_l, 0.052, 0.045, 0.16, Vector3(0, 0.12, 0), mat_dark, Vector3.ZERO, 12)
			_add_cyl(larm_r, 0.052, 0.045, 0.16, Vector3(0, 0.12, 0), mat_dark, Vector3.ZERO, 12)
			_add_cyl(larm_l, 0.034, 0.034, 0.025, Vector3(0.048, 0.13, 0), mat_glow, Vector3(0, 0, PI * 0.5), 12)
			_add_cyl(larm_r, 0.034, 0.034, 0.025, Vector3(-0.048, 0.13, 0), mat_glow, Vector3(0, 0, PI * 0.5), 12)
		"bloodhound":
			# Bloodhound Left Forearm Sonar Tracker Screen & Raven Bracer
			_add_cyl(larm_l, 0.056, 0.048, 0.17, Vector3(0, 0.12, 0), mat_prim, Vector3.ZERO, 12)
			_add_cyl(larm_r, 0.054, 0.046, 0.16, Vector3(0, 0.12, 0), mat_prim, Vector3.ZERO, 12)
			_add_box(larm_l, Vector3(0.03, 0.09, 0.06), Vector3(0.048, 0.13, 0), mat_plasma, Vector3.ZERO, "SonarWristScreen")
		"octane":
			# Octane Glowing Green Stim Syringe Injector on Left Forearm
			_add_cyl(larm_l, 0.048, 0.042, 0.14, Vector3(0, 0.13, 0), mat_dark, Vector3.ZERO, 12)
			_add_cyl(larm_l, 0.018, 0.018, 0.12, Vector3(0.045, 0.13, 0), mat_plasma, Vector3.ZERO, 10, "WristStimTube")
		_:
			# Sleek Tactical Bracers for Ash, Horizon, Valkyrie, Lifeline, Bangalore, Caustic
			_add_cyl(larm_l, 0.050, 0.044, 0.15, Vector3(0, 0.12, 0), mat_sec, Vector3.ZERO, 12)
			_add_cyl(larm_r, 0.050, 0.044, 0.15, Vector3(0, 0.12, 0), mat_sec, Vector3.ZERO, 12)


static func _add_Legend_leg_gear_gen5(thigh_l: Node3D, thigh_r: Node3D, calf_l: Node3D, calf_r: Node3D, lid: String, mat_prim: Material, mat_sec: Material, mat_under: Material, mat_dark: Material, mat_metal: Material, mat_glow: Material, mat_plasma: Material) -> void:
	# Note: in thigh_l/r and calf_l/r local space, +Y runs proximal->distal (0.0 -> 0.38), and -Z is forward!
	match lid:
		"octane":
			# OCTANE SIGNATURE ROBOTIC PROSTHETIC METAL BLADE-RUNNER CALVES!
			_add_cyl(calf_l, 0.062, 0.042, 0.34, Vector3(0, 0.19, 0), mat_metal, Vector3.ZERO, 14, "ProstheticCalfL")
			_add_cyl(calf_r, 0.062, 0.042, 0.34, Vector3(0, 0.19, 0), mat_metal, Vector3.ZERO, 14, "ProstheticCalfR")
			_add_box(calf_l, Vector3(0.04, 0.24, 0.08), Vector3(0, 0.22, 0.03), mat_dark, Vector3.ZERO, "BladeSpringL")
			_add_box(calf_r, Vector3(0.04, 0.24, 0.08), Vector3(0, 0.22, 0.03), mat_dark, Vector3.ZERO, "BladeSpringR")
			_add_cyl(calf_l, 0.066, 0.066, 0.04, Vector3(0, 0.05, 0), mat_plasma, Vector3.ZERO, 12)
			_add_cyl(calf_r, 0.066, 0.066, 0.04, Vector3(0, 0.05, 0), mat_plasma, Vector3.ZERO, 12)
		"pathfinder":
			# PATHFINDER MECHANICAL HYDRAULIC ROBOT THIGHS & PISTON LEGS!
			_add_cyl(thigh_l, 0.078, 0.068, 0.32, Vector3(0, 0.18, 0), mat_prim, Vector3.ZERO, 14, "RobotThighL")
			_add_cyl(thigh_r, 0.078, 0.068, 0.32, Vector3(0, 0.18, 0), mat_prim, Vector3.ZERO, 14, "RobotThighR")
			_add_cyl(calf_l, 0.064, 0.048, 0.34, Vector3(0, 0.19, 0), mat_sec, Vector3.ZERO, 14, "RobotCalfL")
			_add_cyl(calf_r, 0.064, 0.048, 0.34, Vector3(0, 0.19, 0), mat_sec, Vector3.ZERO, 14, "RobotCalfR")
			_add_sphere(calf_l, 0.072, Vector3(0, 0.02, 0), mat_metal, "RobotKneeL")
			_add_sphere(calf_r, 0.072, Vector3(0, 0.02, 0), mat_metal, "RobotKneeR")
		"lifeline":
			# LIFELINE SIGNATURE BAGGY RESCUE CARGO PANTS & POCKETS!
			_add_cyl(thigh_l, 0.095, 0.105, 0.32, Vector3(0, 0.18, 0), mat_sec, Vector3.ZERO, 14, "CargoThighL")
			_add_cyl(thigh_r, 0.095, 0.105, 0.32, Vector3(0, 0.18, 0), mat_sec, Vector3.ZERO, 14, "CargoThighR")
			_add_box(thigh_l, Vector3(0.05, 0.14, 0.12), Vector3(0.085, 0.18, 0), mat_prim, Vector3.ZERO, "CargoPocketL")
			_add_box(thigh_r, Vector3(0.05, 0.14, 0.12), Vector3(-0.085, 0.18, 0), mat_prim, Vector3.ZERO, "CargoPocketR")
			_add_cyl(calf_l, 0.095, 0.078, 0.30, Vector3(0, 0.17, 0), mat_sec, Vector3.ZERO, 14, "CargoCalfL")
			_add_cyl(calf_r, 0.095, 0.078, 0.30, Vector3(0, 0.17, 0), mat_sec, Vector3.ZERO, 14, "CargoCalfR")
		"gibraltar":
			# GIBRALTAR MASSIVE JUGGERNAUT RIOT LEG ARMOR & SHIN PLATES!
			_add_box(thigh_l, Vector3(0.18, 0.30, 0.19), Vector3(0, 0.18, 0), mat_prim, Vector3.ZERO, "GibbyThighL")
			_add_box(thigh_r, Vector3(0.18, 0.30, 0.19), Vector3(0, 0.18, 0), mat_prim, Vector3.ZERO, "GibbyThighR")
			_add_box(calf_l, Vector3(0.16, 0.32, 0.18), Vector3(0, 0.18, -0.01), mat_prim, Vector3.ZERO, "GibbyShinL")
			_add_box(calf_r, Vector3(0.16, 0.32, 0.18), Vector3(0, 0.18, -0.01), mat_prim, Vector3.ZERO, "GibbyShinR")
			_add_box(calf_l, Vector3(0.12, 0.24, 0.04), Vector3(0, 0.18, -0.095), mat_sec)
			_add_box(calf_r, Vector3(0.12, 0.24, 0.04), Vector3(0, 0.18, -0.095), mat_sec)
		"horizon":
			# HORIZON ANTI-GRAVITY SPACEWALK THRUSTER BOOTS!
			_add_cyl(calf_l, 0.078, 0.092, 0.30, Vector3(0, 0.20, 0), mat_under, Vector3.ZERO, 14, "SpaceBootL")
			_add_cyl(calf_r, 0.078, 0.092, 0.30, Vector3(0, 0.20, 0), mat_under, Vector3.ZERO, 14, "SpaceBootR")
			_add_cyl(calf_l, 0.088, 0.088, 0.035, Vector3(0, 0.12, 0), mat_glow, Vector3.ZERO, 14, "GravRingL")
			_add_cyl(calf_r, 0.088, 0.088, 0.035, Vector3(0, 0.12, 0), mat_glow, Vector3.ZERO, 14, "GravRingR")
		"ash":
			# ASH SLEEK CYBERNETIC SIMULACRUM BLADE CALVES!
			_add_cyl(calf_l, 0.062, 0.038, 0.34, Vector3(0, 0.19, 0), mat_prim, Vector3.ZERO, 12, "AshBladeCalfL")
			_add_cyl(calf_r, 0.062, 0.038, 0.34, Vector3(0, 0.19, 0), mat_prim, Vector3.ZERO, 12, "AshBladeCalfR")
			_add_box(calf_l, Vector3(0.03, 0.28, 0.09), Vector3(0, 0.18, -0.04), mat_sec)
			_add_box(calf_r, Vector3(0.03, 0.28, 0.09), Vector3(0, 0.18, -0.04), mat_sec)
		"caustic":
			# CAUSTIC HEAVY CHEMICAL WADER BOOTS!
			_add_cyl(calf_l, 0.085, 0.082, 0.32, Vector3(0, 0.19, 0), mat_dark, Vector3.ZERO, 14)
			_add_cyl(calf_r, 0.085, 0.082, 0.32, Vector3(0, 0.19, 0), mat_dark, Vector3.ZERO, 14)
			_add_box(calf_l, Vector3(0.11, 0.09, 0.05), Vector3(0, 0.04, -0.075), mat_sec)
			_add_box(calf_r, Vector3(0.11, 0.09, 0.05), Vector3(0, 0.04, -0.075), mat_sec)
		_:
			# Armored Knee Pads & Tactical Shin Greaves for Wraith, Bloodhound, Valkyrie, Bangalore, Mirage
			_add_box(calf_l, Vector3(0.095, 0.09, 0.05), Vector3(0, 0.04, -0.07), mat_sec, Vector3.ZERO, "KneePadL")
			_add_box(calf_r, Vector3(0.095, 0.09, 0.05), Vector3(0, 0.04, -0.07), mat_sec, Vector3.ZERO, "KneePadR")
			_add_cyl(calf_l, 0.068, 0.058, 0.24, Vector3(0, 0.21, 0), mat_dark, Vector3.ZERO, 12, "ShinGreaveL")
			_add_cyl(calf_r, 0.068, 0.058, 0.24, Vector3(0, 0.21, 0), mat_dark, Vector3.ZERO, 12, "ShinGreaveR")


static func animate_rig(rig: Node3D, delta: float, s: Dictionary = {}) -> void:
	if rig == null:
		return

	var ual_model: Node3D = rig.get_node_or_null("UALCharacterModel") as Node3D
	if ual_model == null:
		return

	var skels := ual_model.find_children("*", "Skeleton3D", true, false)
	var skel: Skeleton3D = (skels[0] as Skeleton3D) if not skels.is_empty() else null
	if skel == null:
		return

	var bone_map: PackedInt32Array
	if rig.has_meta("bone_map"):
		bone_map = rig.get_meta("bone_map")
	else:
		bone_map = _build_bone_map(skel)
		rig.set_meta("bone_map", bone_map)

	var mode: String = str(s.get("mode", "combat"))
	var lid: String = str(rig.get_meta("legend_id", "wraith"))
	var is_first_person: bool = bool(s.get("is_first_person", false))
	var is_moving: bool = bool(s.get("is_moving", false))
	var is_sprinting: bool = bool(s.get("is_sprinting", false))
	var is_sliding: bool = bool(s.get("is_sliding", false))
	var is_crouching: bool = bool(s.get("is_crouching", false))
	var is_in_air: bool = bool(s.get("is_in_air", false))
	var vel_y: float = float(s.get("vel_y", 0.0))
	var land_compress: float = float(s.get("land_compress", 0.0))
	var is_wall_climbing: bool = bool(s.get("is_wall_climbing", false))
	var is_mantling: bool = bool(s.get("is_mantling", false))
	var is_ziplining: bool = bool(s.get("is_ziplining", false))
	var is_grappling: bool = bool(s.get("is_grappling", false))
	var is_healing: bool = bool(s.get("is_healing", false))
	var is_heirloom: bool = bool(s.get("is_heirloom", false))
	var is_reloading: bool = bool(s.get("is_reloading", false))
	var reload_progress: float = clampf(float(s.get("reload_progress", 0.0)), 0.0, 1.0)
	var is_firing: bool = bool(s.get("is_firing", false))
	var is_melee: bool = bool(s.get("is_melee", false))
	var melee_prog: float = clampf(float(s.get("melee_prog", 0.0)), 0.0, 1.0)
	var melee_combo_idx: int = int(s.get("melee_combo_idx", 0))
	var is_ads: bool = bool(s.get("is_ads", false))
	var aim_pitch: float = float(s.get("aim_pitch", 0.0))
	var move_angle_local: float = float(s.get("move_angle_local", 0.0))
	var flinch: float = float(s.get("flinch", s.get("hit_flinch", 0.0)))
	var speed: float = float(s.get("speed", 6.5))
	var bob_phase: float = float(s.get("strafe_phase", 0.0))

	if not is_sprinting and is_moving and speed > 10.0 and not is_ads and not is_firing and not is_crouching and not is_sliding:
		is_sprinting = true

	# Apply Legend-specific body stature in 3rd-person / Lobby, and invariant 1.0 scale in 1st-person ADS/view
	var target_scale: Vector3 = Vector3.ONE if is_first_person else rig.get_meta("legend_scale", Vector3.ONE)
	ual_model.scale = target_scale

	# 1. Toggle Held Firearm / Held Heirloom / Dual-Wield Left Heirloom / Back Holster / Heal Prop / Body Attachments
	var held_wep: Node3D = ual_model.find_child("HeldWeaponRoot", true, false) as Node3D
	var held_hl: Node3D = ual_model.find_child("HeldHeirloomRoot", true, false) as Node3D
	var held_left_hl: Node3D = ual_model.find_child("HeldLeftHeirloomRoot", true, false) as Node3D
	var back_holster: Node3D = ual_model.find_child("BackHolsterRoot", true, false) as Node3D
	var heal_prop: Node3D = ual_model.find_child("HealPropRoot", true, false) as Node3D
	var jet_l: Node3D = ual_model.find_child("JumpkitJetL", true, false) as Node3D
	var jet_r: Node3D = ual_model.find_child("JumpkitJetR", true, false) as Node3D
	var head_att: Node3D = ual_model.find_child("HeadBoneAttachment", true, false) as Node3D
	var chest_att: Node3D = ual_model.find_child("ChestBoneAttachment", true, false) as Node3D
	var pelvis_att: Node3D = ual_model.find_child("PelvisBoneAttachment", true, false) as Node3D
	var uarm_l: Node3D = ual_model.find_child("LeftUpperArmAttachment", true, false) as Node3D
	var uarm_r: Node3D = ual_model.find_child("RightUpperArmAttachment", true, false) as Node3D

	var larm_l: Node3D = ual_model.find_child("LeftLowerArmAttachment", true, false) as Node3D
	var larm_r: Node3D = ual_model.find_child("RightLowerArmAttachment", true, false) as Node3D
	var hands_busy: bool = (is_healing or is_wall_climbing or is_mantling)

	# AAA Full-Body Shadow Casting + Lower-Body Awareness Visibility:
	# Upper-body attachments use `SHADOW_CASTING_SETTING_SHADOWS_ONLY` in 1st-person so the player casts a
	# complete full-body shadow (helmet, chest armor, wings, arms, rifle/heirloom) on the ground without camera clipping!
	_set_subtree_fp_shadow_mode(held_wep, (not is_heirloom) and (not hands_busy), is_first_person)
	_set_subtree_fp_shadow_mode(held_hl, is_heirloom and (not hands_busy), is_first_person)
	_set_subtree_fp_shadow_mode(held_left_hl, is_heirloom and (not hands_busy) and (lid == "pathfinder" or lid == "lifeline" or lid == "ash"), is_first_person)
	_set_subtree_fp_shadow_mode(back_holster, is_heirloom or hands_busy, is_first_person)
	_set_subtree_fp_shadow_mode(heal_prop, is_healing, is_first_person)
	_set_subtree_fp_shadow_mode(head_att, true, is_first_person)
	_set_subtree_fp_shadow_mode(chest_att, true, is_first_person)
	_set_subtree_fp_shadow_mode(uarm_l, true, is_first_person)
	_set_subtree_fp_shadow_mode(uarm_r, true, is_first_person)
	_set_subtree_fp_shadow_mode(larm_l, true, is_first_person)
	_set_subtree_fp_shadow_mode(larm_r, true, is_first_person)
	if pelvis_att:
		pelvis_att.visible = true

	var jets_active: bool = (not is_first_person) and (is_sliding or is_in_air or is_ziplining or is_grappling or is_wall_climbing)
	if jet_l:
		jet_l.visible = jets_active
	if jet_r:
		jet_r.visible = jets_active

	# 2. Keep ual_model grounded on the floor (y = 0.0, pitch = 0.0); in 1st-person shift pelvis +0.20m back (+Z)
	#    so looking straight down (-80 deg) views the front of the waist, thighs, knees, and boots without clipping!
	var yaw_twist: float = clampf(move_angle_local * 0.40, -0.48, 0.48) if is_moving else 0.0
	var target_z_ofs: float = (0.04 if is_sliding else 0.20) if is_first_person else 0.0
	ual_model.position.x = lerpf(ual_model.position.x, 0.0, delta * 18.0)
	ual_model.position.y = lerpf(ual_model.position.y, 0.0, delta * 18.0)
	ual_model.position.z = lerpf(ual_model.position.z, target_z_ofs, delta * 18.0)
	ual_model.rotation.x = lerpf(ual_model.rotation.x, 0.0, delta * 18.0)
	ual_model.rotation.y = lerp_angle(ual_model.rotation.y, PI + yaw_twist, delta * 14.0)

	# 3. Swap between Lower-Body Full-Awareness Mesh + Full-Body Shadow Caster (in 1st-person) and Full-Body Mesh (in 3rd-person / Lobby)
	for child in ual_model.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null:
			continue
		if mi.name == "FPShadowCasterBody":
			mi.visible = is_first_person
		elif mi.has_meta("full_mesh"):
			var desired_m: Mesh = mi.get_meta("lower_body_mesh") if is_first_person else mi.get_meta("full_mesh")
			if desired_m != null and mi.mesh != desired_m:
				mi.mesh = desired_m
				mi.set_surface_override_material(0, mi.get_meta("mat_0"))
				if mi.mesh.get_surface_count() > 1:
					mi.set_surface_override_material(1, mi.get_meta("mat_1"))

	var thigh_l_att: Node3D = ual_model.find_child("LeftThighAttachment", true, false) as Node3D
	var thigh_r_att: Node3D = ual_model.find_child("RightThighAttachment", true, false) as Node3D
	var calf_l_att: Node3D = ual_model.find_child("LeftCalfAttachment", true, false) as Node3D
	var calf_r_att: Node3D = ual_model.find_child("RightCalfAttachment", true, false) as Node3D
	if thigh_l_att: thigh_l_att.visible = true
	if thigh_r_att: thigh_r_att.visible = true
	if calf_l_att: calf_l_att.visible = true
	if calf_r_att: calf_r_att.visible = true

	var prev_clip: String = str(rig.get_meta("anim_clip", "Pistol_Idle_Loop"))
	var anim_time: float = float(rig.get_meta("anim_time", 0.0))

	if mode == "lobby":
		anim_time += delta * 0.95
		rig.set_meta("anim_clip", "Pistol_Idle_Loop")
		rig.set_meta("anim_time", anim_time)
		_sample_mocap_clip_to_skeleton(skel, bone_map, "Pistol_Idle_Loop", anim_time, true)
		_apply_upper_body_rifle_combat_stance(skel, bone_map, anim_time, 0.0, false, false, false)
		var sp1_lobby: int = bone_map[2]
		if sp1_lobby >= 0:
			var q_sp1_base := Quaternion(-0.0647, 0.0, 0.0, 0.9979)
			skel.set_bone_pose_rotation(sp1_lobby, q_sp1_base * Quaternion(Vector3.RIGHT, 0.185))
		return
	elif mode == "death":
		if prev_clip != "Death01":
			anim_time = 0.0
		else:
			anim_time += delta * 1.15
		rig.set_meta("anim_clip", "Death01")
		rig.set_meta("anim_time", anim_time)
		_sample_mocap_clip_to_skeleton(skel, bone_map, "Death01", anim_time, false)
		return

	# =========================================================================
	# 4. HIERARCHICAL 3-LAYER PER-BONE ANIMATION BLENDING ENGINE
	#    (`骨骼分层动画混合架构 — 解决换弹/打药/近战/射击时走路动作消失问题!`)
	# =========================================================================
	# LAYER 0: Lower-Body Locomotion State Machine (`pelvis` [1] + `thigh_l..ball_r` [55..64])
	# Driven strictly by movement & posture so the legs NEVER stop walking/running/crouching
	# when the upper body is reloading (`换弹`), healing (`打药`), shooting (`射击`), or meleeing (`近战`)!
	var loco_clip: String = "Pistol_Idle_Loop"
	var loco_speed: float = 1.0
	var loco_loop: bool = true

	if is_wall_climbing or is_mantling:
		loco_clip = "ClimbUp_1m"
		loco_speed = 1.45
	elif is_in_air or is_ziplining or is_grappling:
		var use_ninja: bool = (lid == "wraith" or lid == "octane" or lid == "ash" or lid == "valkyrie")
		if vel_y > 1.8:
			loco_clip = "NinjaJump_Start" if use_ninja else "Jump_Start"
			loco_speed = 1.25
			loco_loop = false
		else:
			loco_clip = "NinjaJump_Idle_Loop" if use_ninja else "Jump_Loop"
			loco_speed = 1.05
	elif is_sliding:
		loco_clip = "Slide_Loop"
		loco_speed = 1.15
	elif is_crouching:
		if is_moving:
			loco_clip = "Crouch_Fwd_Loop"
			loco_speed = clampf(speed / 4.2, 0.90, 1.45)
		else:
			loco_clip = "Crouch_Idle_Loop"
	elif is_moving:
		if is_sprinting and not is_healing and not is_ads:
			loco_clip = "Sprint_Loop"
			loco_speed = clampf(speed / 9.8, 0.95, 1.50)
		elif speed > 4.2 and not is_ads and not is_healing:
			loco_clip = "Jog_Fwd_Loop"
			loco_speed = clampf(speed / 6.8, 0.95, 1.45)
		else:
			loco_clip = "Walk_Loop"
			loco_speed = clampf(speed / 4.2, 0.90, 1.38)
	else:
		if land_compress > 0.35:
			loco_clip = "Jump_Land"
			loco_speed = 1.6
			loco_loop = false
		elif is_heirloom and not is_reloading and not is_healing:
			loco_clip = "Sword_Idle"
		else:
			loco_clip = "Pistol_Idle_Loop"

	var prev_loco_clip: String = str(rig.get_meta("loco_clip", "Pistol_Idle_Loop"))
	var loco_time: float = float(rig.get_meta("loco_time", 0.0))
	if prev_loco_clip != loco_clip:
		loco_time = 0.0
	else:
		loco_time += delta * loco_speed
	rig.set_meta("loco_clip", loco_clip)
	rig.set_meta("loco_time", loco_time)
	rig.set_meta("anim_clip", loco_clip)
	rig.set_meta("anim_time", loco_time)

	# Sample Layer 0 onto all 65 bones (setting pelvis position + leg rotations!)
	_sample_mocap_clip_to_skeleton(skel, bone_map, loco_clip, loco_time, loco_loop)
	var pel_skel_idx: int = bone_map[1]
	var q_pelvis_loco: Quaternion = skel.get_bone_pose_rotation(pel_skel_idx) if pel_skel_idx >= 0 else Quaternion.IDENTITY

	# =========================================================================
	# LAYER 1: Upper-Body Action Override Layer (`spine_01..Head` [2..6] + Arms [7..54])
	# Evaluates Reload, Healing (Battery/Syringe), Melee/Heirloom Slash, Sprint Carry, or
	# Two-Handed Rifle Combat Stance independently on top of the moving lower body!
	# =========================================================================
	var upper_time: float = float(rig.get_meta("upper_time", 0.0)) + delta
	rig.set_meta("upper_time", upper_time)
	var q_pelvis_upper_ref: Quaternion = q_pelvis_loco
	var needs_pelvis_decouple: bool = false

	if is_wall_climbing or is_mantling:
		needs_pelvis_decouple = false
	elif is_melee:
		q_pelvis_upper_ref = _apply_upper_body_melee_choreography(skel, bone_map, lid, is_heirloom, melee_combo_idx, melee_prog)
		needs_pelvis_decouple = true
	elif is_healing:
		q_pelvis_upper_ref = _apply_upper_body_healing_choreography(skel, bone_map, upper_time)
		needs_pelvis_decouple = true
	elif is_reloading:
		q_pelvis_upper_ref = _apply_upper_body_tactical_reload(skel, bone_map, reload_progress)
		needs_pelvis_decouple = true
	elif is_heirloom:
		q_pelvis_upper_ref = _sample_upper_body_clip_only(skel, bone_map, "Sword_Idle", upper_time, true)
		if is_moving:
			var hl_sway: float = sin(bob_phase) * (0.14 if is_sprinting else 0.06)
			_mult_bone_rot(skel, bone_map, 32, Quaternion(Vector3.RIGHT, hl_sway))
			_mult_bone_rot(skel, bone_map, 8, Quaternion(Vector3.RIGHT, -hl_sway))
		needs_pelvis_decouple = true
	elif is_sprinting and is_moving and not is_firing and not is_ads and not is_crouching and not is_sliding:
		q_pelvis_upper_ref = _apply_upper_body_sprint_carry(skel, bone_map, upper_time, bob_phase)
		needs_pelvis_decouple = true
	else:
		q_pelvis_upper_ref = _apply_upper_body_rifle_combat_stance(skel, bone_map, upper_time, bob_phase, is_moving, is_ads, is_firing)
		needs_pelvis_decouple = true

	# =========================================================================
	# LAYER 2: Pelvis-Rotation Decoupling + Aim Pitch + Strafe Counter-Twist + Hit Flinch
	# =========================================================================
	if not is_wall_climbing and not is_mantling:
		var spine01_idx: int = bone_map[2]
		if spine01_idx >= 0:
			var q_sp1_cur: Quaternion = skel.get_bone_pose_rotation(spine01_idx)
			var q_decouple: Quaternion = (q_pelvis_loco.inverse() * q_pelvis_upper_ref) if needs_pelvis_decouple else Quaternion.IDENTITY
			var level_trim: float = 0.185 if not is_heirloom else 0.04
			var pitch_rad: float = clampf(level_trim - aim_pitch, -0.92, 0.92)
			var q_pitch := Quaternion(Vector3.RIGHT, pitch_rad)
			var q_yaw_comp := Quaternion(Vector3.UP, -yaw_twist)
			skel.set_bone_pose_rotation(spine01_idx, q_decouple * q_sp1_cur * q_yaw_comp * q_pitch)
		if flinch > 0.05:
			var flinch_w: float = clampf(flinch, 0.0, 1.0) * 0.28
			_mult_bone_rot(skel, bone_map, 3, Quaternion(Vector3.RIGHT, -flinch_w) * Quaternion(Vector3.FORWARD, flinch_w * 0.6))

	# 8. Animate Unified HeldWeaponRoot Mechanical Parts (`MagPivot`, `BoltPivot`, `MuzzleFlashNode`)
	if held_wep != null:
		var mag_piv: Node3D = held_wep.find_child("MagPivot", true, false) as Node3D
		var bolt_piv: Node3D = held_wep.find_child("BoltPivot", true, false) as Node3D
		var flash_node: Node3D = held_wep.find_child("MuzzleFlashNode", true, false) as Node3D
		var bot_flash: Node3D = held_wep.find_child("BotMuzzleFlash", true, false) as Node3D
		var show_flash: bool = is_firing and ((int(Time.get_ticks_msec() / 32) % 2) == 0)
		if flash_node:
			flash_node.visible = show_flash
		if bot_flash:
			bot_flash.visible = show_flash
		if mag_piv:
			if not mag_piv.has_meta("base_pos"):
				mag_piv.set_meta("base_pos", mag_piv.position)
			var base_mp: Vector3 = mag_piv.get_meta("base_pos")
			if is_reloading:
				var drop_amt: float = 0.0
				if reload_progress >= 0.10 and reload_progress < 0.42:
					drop_amt = clampf((reload_progress - 0.10) / 0.22, 0.0, 1.0)
				elif reload_progress >= 0.42 and reload_progress < 0.68:
					drop_amt = 1.0 - clampf((reload_progress - 0.42) / 0.22, 0.0, 1.0)
				mag_piv.position = base_mp + Vector3(-0.04 * drop_amt, -0.22 * drop_amt, 0.02 * drop_amt)
			else:
				mag_piv.position = base_mp
		if bolt_piv:
			if not bolt_piv.has_meta("base_pos"):
				bolt_piv.set_meta("base_pos", bolt_piv.position)
			var base_bp: Vector3 = bolt_piv.get_meta("base_pos")
			if is_reloading and reload_progress >= 0.68 and reload_progress <= 0.92:
				var rack_t: float = sin(((reload_progress - 0.68) / 0.24) * PI)
				bolt_piv.position = base_bp + Vector3(0.0, 0.0, 0.065 * rack_t)
			elif is_firing:
				var fire_t: float = float(int(Time.get_ticks_msec() / 25) % 2)
				bolt_piv.position = base_bp + Vector3(0.0, 0.0, 0.045 * fire_t)
			else:
				bolt_piv.position = base_bp
