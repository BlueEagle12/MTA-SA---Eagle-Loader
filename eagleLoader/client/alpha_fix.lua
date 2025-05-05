
local RAW_ALPHA_FIX_SHADER = [[
    technique AlphaFix {
        pass P0 { }
    }
]]

local function applyAlphaFix()
    local shader = dxCreateShader(RAW_ALPHA_FIX_SHADER, 1, 0, true, "object,world")
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
