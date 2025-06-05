local RAW_ALPHA_FIX_SHADER = [[
technique AlphaFix {
    pass P0 { }
}
]]

-- Shader file path and textures to apply must be set
local ALPHA_FIX_SHADER_PATH = "client/alpha_fix.fx"  -- Change if needed

-- Create shader up front (or set to nil if not using a file)
local alphaFixShader = nil

local function createAlphaFixShader()
    if enableAlphaFix2 then
        alphaFixShader = dxCreateShader(ALPHA_FIX_SHADER_PATH, 1, 0, false, "object,world")
    else
        alphaFixShader = dxCreateShader(RAW_ALPHA_FIX_SHADER, 1, 0, true, "object,world")
    end
    return alphaFixShader
end

local function applyAlphaFix()
    -- Create (or re-use) shader
    if not alphaFixShader then
        if not createAlphaFixShader() then
            outputDebugString("Failed to create alpha fix shader.", 1)
            return
        end
    end

    if not alphaFixApply or type(alphaFixApply) ~= "table" then
        outputDebugString("alphaFixApply texture list not defined.", 1)
        return
    end

    for _, textureName in ipairs(alphaFixApply) do
        engineApplyShaderToWorldTexture(alphaFixShader, textureName)
    end
end

if enableAlphaFix then
    addEventHandler("onClientResourceStart", resourceRoot, applyAlphaFix)
end
