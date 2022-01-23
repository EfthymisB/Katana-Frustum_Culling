
-- ______________________________ --
--|                              |--
--|  Author: Efthymis B.         |--
--|  Last Modified: 22/01/2022   |--
--|                              |--
--|  Frustum Culling OpScript    |--
--|______________________________|--



-----------------------------------------------------------------------------
--------------------------------- Functions ---------------------------------
-----------------------------------------------------------------------------

function getBB(points, meshPos)
    --[[
    Calculate the bounds if they don't exist
    Could be very expensive when there are many points
    ]]
    -- Initialise min and max vecotrs
    local bbmax = Imath.V3d({-math.huge, -math.huge, -math.huge})
    local bbmin = Imath.V3d({math.huge, math.huge, math.huge})

    for point=0, #points/3-1 do

        -- If the point's position is greater then max
        -- or less than min, update the corresponding attribute
        if points[3*point + 1] > bbmax[0] then
            bbmax[0] = points[3*point + 1]
        elseif points[3*point + 1] < bbmin[0] then
            bbmin[0] = points[3*point + 1]
        end

        if points[3*point + 2] > bbmax[1] then
            bbmax[1] = points[3*point + 2]
        elseif points[3*point + 2] < bbmin[1] then
            bbmin[1] = points[3*point + 2]
        end

        if points[3*point + 3] > bbmax[2] then
            bbmax[2] = points[3*point + 3]
        elseif points[3*point + 3] < bbmin[2] then
            bbmin[2] = points[3*point + 3]
        end
    end

    Interface.SetAttr('bound', FloatAttribute({bbmin[0], bbmax[0], bbmin[1], bbmax[1], bbmin[2], bbmax[2]}, 2))

    return Imath.Box3d(bbmin * meshPos, bbmax * meshPos)
end

function contains(list, x)
	for _, v in pairs(list) do
		if v == x then return true end
	end
	return false
end

-----------------------------------------------------------------------------
----------------------------- Read op arguments -----------------------------
-----------------------------------------------------------------------------

-- Get current location
local loc = Interface.GetInputLocationPath()

-- Get Calculation Method option
local calcMethod = Interface.GetOpArg("user.calcMethod"):getValue()

-- Get hide viewport/renmder options
local hideViewport = Interface.GetOpArg("user.viewportVisibility"):getValue()
local hideRender = Interface.GetOpArg("user.renderVisibility"):getValue()

-- Get CalcBounds option
local calcBounds = Interface.GetOpArg("user.calcBounds"):getValue()

-- Get Color values
local useCd = Interface.GetOpArg("user.colors.cd"):getValue()
local useDepthCd = Interface.GetOpArg("user.colors.depthCd"):getValue()
local visCd = Interface.GetOpArg("user.colors.visCd")
local invisCd = Interface.GetOpArg("user.colors.invisCd")
local midCd = Interface.GetOpArg("user.colors.midCd")
local farCd = Interface.GetOpArg("user.colors.farCd")

-- Get Mid/Far distance
local midDist = Interface.GetOpArg("user.colors.midDist"):getValue()
local farDist = Interface.GetOpArg("user.colors.farDist"):getValue()

-- Get Camera location and manual aspect ratio option
local cam_location = Interface.GetOpArg("user.camera.path"):getValue()

-- Get fustrum offset value
local frustumOffset = Interface.GetOpArg("user.camera.frustumOffset"):getValue()

-- Get aspect ratio
local getResAttr = Interface.GetOpArg("user.camera.res"):getNearestSample(0)[1]
local resTable = ResolutionTable.GetResolution(getResAttr)
local aspectRatio = resTable:getAspectRatio()

-- Get Custom Attribute options
local insideAttr = Interface.GetOpArg("user.attributes.inside"):getValue()
local nearAttr = Interface.GetOpArg("user.attributes.nearAttr"):getValue()
local midAttr = Interface.GetOpArg("user.attributes.midAttr"):getValue()
local farAttr = Interface.GetOpArg("user.attributes.farAttr"):getValue()
local distanceAttr = Interface.GetOpArg("user.attributes.distanceAttr"):getValue()

-----------------------------------------------------------------------------
-------------------------- Get Camera's Attributes --------------------------
-----------------------------------------------------------------------------

-- Get camera's attributes
local fov_degrees = Interface.GetAttr('geometry.fov', cam_location):getValue()
local near_clip = Interface.GetAttr('geometry.near', cam_location):getValue()
local far_clip = Interface.GetAttr('geometry.far', cam_location):getValue()
--local projection = Interface.GetAttr('geometry.projection', cam_location):getValue()

-- Convert FOV to radians
local fovx = 0
local fovy = fov_degrees * 3.141592 / 180 + frustumOffset

-- Get Adjust window method and set fovx/fovy accordingly
local adjustWindow = Interface.GetOpArg("user.camera.adjustScreenWindow"):getNearestSample(0)[1]
if adjustWindow == 'Adjust height to match resolution' then
    fovx, fovy = fovy, fovx
end

-- Get camera's matrix --> convertix to Imath.M44d
local cam_XFormMatrix = XFormUtils.CalcTransformMatrixAtTime(Interface.GetGlobalXFormGroup(cam_location), 0.0):getNearestSample(0.0)
local cam_M44Matrix = Imath.M44d(cam_XFormMatrix)
local cam_pos = cam_M44Matrix:translation()

-- Create Frustum and check if projection is orthographic
local frustum = Imath.Frustumd(near_clip, far_clip, fovx, fovy, aspectRatio)

-- Link Frustum with the camera
local cam_frustum = Imath.FrustumTestd(frustum, cam_M44Matrix)

local cam_axis = Imath.V4d({0, 0, -1, 0})*Imath.M44d(cam_XFormMatrix)
local cam_axis = Imath.V3d({cam_axis.x,cam_axis.y,cam_axis.z})
local cam_axis = cam_axis:normalized()

-----------------------------------------------------------------------------
------------------------------- Frustum Script ------------------------------
-----------------------------------------------------------------------------

-- If on Root, set camera resolution settings and exit
if loc == '/root' then
    local adjustWindow = Interface.GetOpArg("user.camera.adjustScreenWindow"):getNearestSample(0)[1]
    Interface.SetAttr('renderSettings.resolution', StringAttribute(getResAttr))
    Interface.SetAttr('renderSettings.adjustScreenWindow', StringAttribute(adjustWindow))
    Interface.SetAttr('renderSettings.cameraName', StringAttribute(cam_location))
    do return end
end

-- Get currelt location type
local loc_type = Interface.GetAttr('type', loc):getValue()

local validTypes = {'polymesh', 'subdmesh', 'sphere', 'group'}

if contains(validTypes, loc_type) then

    local visible = false

    -- Get transform matrix -> convert to data -> extract translation
    local meshXformAttr = XFormUtils.CalcTransformMatrixAtTime(Interface.GetGlobalXFormGroup(Interface.GetInputLocationPath()), 0.0)
    local meshXformData = meshXformAttr:getNearestSample(0)
    local meshPos = Imath.M44d(meshXformData):translation()

    -- Declare variables
    local target
    local distance = math.huge

    if loc_type == 'group' then
        if calcMethod == 'xFormGrp' then
            if cam_frustum:isVisible(Imath.V3d(meshPos)) then
                    visible = true
                    target = Imath.V3d(meshPos) - Imath.V3d(cam_pos)
                    distance = target:dot(cam_axis)
            end
        elseif calcMethod == 'boundsGrp' then
            local bbBox
            local bounds = Interface.GetAttr('bound')

            -- Check if object has bounds
            if bounds then
                local bounds = bounds:getNearestSample(0)
                local bbMin = Imath.V3d(bounds[1], bounds[3], bounds[5])
                local bbMax = Imath.V3d(bounds[2], bounds[4], bounds[6])
                bbBox = Imath.Box3d(bbMin, bbMax):transform(Imath.M44d(meshXformData))

            else
                -- Repot error if no bounds founds
                Interface.ReportError('No bounds found. Please make sure Group inherit geo bounds.')
                do return end
            end

            if cam_frustum:isVisible(bbBox) then
                visible = true
                target = bbBox:closestPointInBox(cam_pos) - Imath.V3d(cam_pos)
                distance = math.abs(target:dot(cam_axis))
            end
        end
    else
        if calcMethod == 'xFormGeo' then
            if cam_frustum:isVisible(Imath.V3d(meshPos)) then
                    visible = true
                    target = Imath.V3d(meshPos) - Imath.V3d(cam_pos)
                    distance = target:dot(cam_axis)
            end
        elseif calcMethod == 'boundsGeo' then

            local bbBox
            local bounds = Interface.GetAttr('bound')

            -- Check if object has bounds
            if bounds then
                local bounds = bounds:getNearestSample(0)
                local bbMin = Imath.V3d(bounds[1], bounds[3], bounds[5])
                local bbMax = Imath.V3d(bounds[2], bounds[4], bounds[6])
                bbBox = Imath.Box3d(bbMin, bbMax):transform(Imath.M44d(meshXformData))

            else
                -- If noop bounds found, we will calculate them
                -- This could be very computationally expensive
                -- Get points' position
                local pointAttr = Interface.GetAttr("geometry.point.P")

                if pointAttr then
                    if calcBounds == 1 then
                        local points = pointAttr:getNearestSample(0)
                        bbBox = getBB(points, Imath.M44d(meshXformData))
                        Interface.ReportWarning('No bounds found. Manually calculating Bounds can be computationally expensive.')
                    else
                        Interface.ReportError('No bounds found. Please make sure Group inherit geo bounds.')
                        do return end
                    end
                end
            end

            if cam_frustum:isVisible(bbBox) then
                visible = true
                target = bbBox:closestPointInBox(cam_pos) - Imath.V3d(cam_pos)
                distance = math.abs(target:dot(cam_axis))
            end

        end
    end

    if visible then
            if distanceAttr == 1 then
                Interface.SetAttr('frustum.distance.distance', FloatAttribute(distance))
            end

            if hideViewport == 1 then
                Interface.SetAttr('viewer.default.drawOptions.hide', IntAttribute(0))
            end

            if insideAttr == 1 then
                Interface.SetAttr('frustum.inside', IntAttribute(1))
            end

            if useCd == 1 then
                Interface.SetAttr('viewer.default.drawOptions.color', visCd)
            end

            if distance < midDist then
                if useCd == 1 then
                    Interface.SetAttr('viewer.default.drawOptions.color', visCd)
                end
                if nearAttr == 1 then
                    Interface.SetAttr('frustum.distance.near', IntAttribute(1))
                end
            elseif distance > midDist and distance < farDist then
                if useDepthCd == 1 and useCd == 1 then
                    Interface.SetAttr('viewer.default.drawOptions.color', midCd)
                end
                if midAttr == 1 then
                    Interface.SetAttr('frustum.distance.mid', IntAttribute(1))
                end
            elseif distance > farDist then
                if useDepthCd == 1 and useCd == 1 then
                    Interface.SetAttr('viewer.default.drawOptions.color', farCd)
                end
                if farAttr == 1 then
                    Interface.SetAttr('frustum.distance.far', IntAttribute(1))
                end
            end
    else
        if insideAttr == 1 then
            Interface.SetAttr('frustum.inside', IntAttribute(0))
        end

        if hideViewport == 1 then
                Interface.SetAttr('viewer.default.drawOptions.hide', IntAttribute(1))
        end

        if hideRender == 1 then
            Interface.SetAttr('visibility', IntAttribute(0))
        end

        if useCd == 1 then
            Interface.SetAttr('viewer.default.drawOptions.color', invisCd)
        end
    end

elseif loc_type == 'pointcloud' then

    -- Get visible / invisible width
    local visibleWidth = Interface.GetOpArg("user.pointcloud.visibleWidth"):getValue()
    local invisibleWidth = Interface.GetOpArg("user.pointcloud.invisibleWidth"):getValue()
    local skipIndexAttr = Interface.GetOpArg("user.pointcloud.skipIndex"):getValue()

    -- Get poiont Cloud location and xform
    --local usePointCloudXform = Interface.GetOpArg("user.usePointCloudXform"):getValue()

    -- Get points' position
    local pointAttr = Interface.GetAttr("geometry.point.P", loc)
    local points = pointAttr:getNearestSample(0)

    -- Set the xform on the instance array to match the point cloud
    --if usePointCloudXform == 1 then

    pcxform = Interface.GetAttr('xform', loc)
    if pcxform then

        -- Convert pointCloud's GroupXForm to Matrix (4x4)
        pc_XFormMatrix = XFormUtils.CalcTransformMatrixAtTime(pcxform, 0.0):getNearestSample(0.0)

        -- Convert Matrix to Imath.M44d format
        pc_M44Matrix = Imath.M44d(pc_XFormMatrix)
    end

    custom_width = {}
    skipIndex = {}

    for i=0,#points/3-1 do

        -- Grab points position and create a vector
        tran_X = points[3*i + 1]
        tran_Y = points[3*i + 2]
        tran_Z = points[3*i + 3]
        pPos = Imath.V3d(tran_X, tran_Y, tran_Z)

        local target = pPos - cam_pos
        local distance = target:dot(cam_axis)

        -- Creat a Matrix and then set translation
        point_Matrix = Imath.M44d()
        Imath.M44d().translate(point_Matrix, pPos)

        -- If pointCloudXForm is enabled, multiply the matrix with it
        if pcxform then
            point_Matrix = point_Matrix * pc_M44Matrix
        end

        -- If point inside fustrum, set skipIndex variable and chage its width
        if cam_frustum:isVisible(point_Matrix:translation()) then
            custom_width[#custom_width+1] = visibleWidth
        else
            custom_width[#custom_width+1]= invisibleWidth
            skipIndex[#skipIndex+1] = i
        end
    end

    Interface.SetAttr("geometry.point.width", FloatAttribute(custom_width))
    if skipIndexAttr == 1 then
        Interface.SetAttr("geometry.instanceSkipIndex", IntAttribute(skipIndex))
    end

elseif loc_type == 'instance array' then

    local instancePairsAttr = Interface.GetOpArg('user.locs.test')
    if instancePairsAttr then
        local instancePairs = instancePairsAttr:getNearestSample(0)

        for i=0, #instancePairs-1 do
            if instancePairs[i+1] == loc then
                local pcSkipIndex = Interface.GetGlobalAttr('geometry.point.P', instancePairs[i])
            end
        end
    end
end

