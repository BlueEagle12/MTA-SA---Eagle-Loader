


-- ===========================
-- IMG loading
-- ===========================
IMGNames = {'dff','col','txd','custom'}  -- What IMG file names should the streamer look for
maxIMG = 2                               -- How many of each IMG file will it check for ("Example txd_1.img, txd_2.img")


-- ===========================
-- Streaming & Distances
-- ===========================

streamEverything            = true       -- Set to true to stream all elements by default
removeDefaultMap            = true       -- Disable if you'd like to keep the SA map
removeDefaultInteriors      = true       -- Disable if you'd like to keep default interiors
allocateDefaultIDs          = true       -- Allow the streamer to use IDs from SAs map, Disable if you'd like to keep the SA map or use buildings from it
highDefLODs                 = false      -- Remove default LODs and just make every model its own LOD
streamingMemoryAllowcation  = 512        -- (Default : 512) If you experience pop-in increase this. Max tested stable : 1024
streamingBufferAllowcation  = 150        -- (Default : 150) If you experience pop-in increase this. Max tested stable : 512
drawDistanceMultiplier      = 1.5        -- (Default : 1.5) Increase drawdistance by this amount, if you experience pop-in or performance issues lower this
modelCrashDebug             = false      -- Do not load map, but at 0,0,0 spawn every object consecutively and output the last spawned model in debug.txt; use this to track down crashes

-- ===========================
-- LOD Attachments
-- ===========================
lodAttach = {                           -- Anything that LODs should be attached to, currently includes Tram for LC.
    ["Tram"] = true
}


-- ===========================
-- Other
-- ===========================


alphaFixApply = {"*plant*", "*grass*", "*foliage*", "*flower*", "*leave*", "*fern*","*palm*", "kbtree4_test"} -- List of textures to apply alpha fix to
enableAlphaFix          = true       -- Fix alpha blending on trees and other objects, disable if it interfers with shaders (See alpha_fix.lua)
enableAlphaFix2         = false      -- Enable experimental alpha fix shader. (WIP)
