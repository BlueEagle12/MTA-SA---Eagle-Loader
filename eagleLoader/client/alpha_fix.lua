
local RAW_ALPHA_FIX_SHADER = [[
    technique AlphaFix {
        pass P0 { }
    }
]]


local alphaFix2 = dxCreateShader('client/alpha_fix.fx', 1, 0, false, "object,world")

local function applyAlphaFix()
    local shader = (enableAlphaFix2 and alphaFix2) and alphaFix2 or dxCreateShader(RAW_ALPHA_FIX_SHADER, 1, 0, true, "object,world")
    if not shader then
        outputDebugString("Failed to create alpha fix shader.", 1)
        return
    end

    for _, textureName in ipairs(alphaFixApply) do
        engineApplyShaderToWorldTexture(shader, textureName)
    end
end

if enableAlphaFix then
    addEventHandler("onClientResourceStart", resourceRoot, applyAlphaFix)
end
