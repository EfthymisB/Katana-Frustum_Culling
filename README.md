![](https://img.shields.io/github/last-commit/EfthymisB/Katana-Frustum_Culling)

## Katana - Frustum Culling
by Efthymis B.

---
![](https://img.shields.io/badge/Lua-000090?logo=lua&logoColor=white)
![](https://img.shields.io/badge/Katana-4.0v5+-FCB123?logo=katana&logoColor=white)

### This OpScript calculates what is inside the Camera's Frustum and creates Attributes accordingly.

- Hide geometry that is outside of the Frustum (from the viewport)

- Set Visibility Attribute (for render)

- Create Attributes based on distance from the camera.

- Create instanceSkipIndex attribute for PointClouds.

https://user-images.githubusercontent.com/87680516/150698838-2dd947b6-80b2-4ac3-9f77-c4db6fcfedba.mp4

---

## How to use

1. In order to be able to see Camera Resolution changes, the root should be included in the location paths.
2. Then add Geometry (types: **polymesh**, **subdmesh**, **sphere**) and/or Pointcloud (type: **pointcloud**) locations.


Example:

![path_example](https://user-images.githubusercontent.com/87680516/150696163-3f347bc9-59bf-4409-ad38-6f06bb8a5119.png)


> *You can combine locations using expressions as usual.*

3. Add the Camera's location path in `user.camera.path` and change the camera settings according to your needs.

![camera_settings](https://user-images.githubusercontent.com/87680516/150817242-4858f788-2166-4b5f-9080-b6eae2ffbbfc.png)

4. Set the preferable calculation method and Viewport/Render visibility.

> Refer to Help Text for more details. 

<img alt="katanaCatalogScript" src="https://user-images.githubusercontent.com/87680516/150820042-121cce54-8564-4485-a9b9-201dbe259ef5.png" width="550"/><br>

5. Enabled/Disable viewport color representation for objects inside/outside the Frustum. Enable `Depth Colors` to preview objects based on distance from the camera.

<img alt="katanaCatalogScript" src="https://user-images.githubusercontent.com/87680516/150820063-69dd12e0-a60b-45e6-8dc7-b713fb2f0e37.png" width="550"/><br>

6. Enable/Disable attributes.

<img alt="katanaCatalogScript" src="https://user-images.githubusercontent.com/87680516/150820050-03a989e2-16e5-4b0e-85de-ccd44d3045a1.png" width="550"/><br>

7. Add `instanceSkipIndex` attribute for points outside the Frustum (*only for Pointclouds*).

> Then copy the `instanceSkipIndex` attribute to your `instance array` location. 

<img alt="katanaCatalogScript" src="https://user-images.githubusercontent.com/87680516/150820069-892acf40-fd6d-467f-8d07-d5df58c78797.png" width="550"/><br>

> For more information, refer to the Help Text of each option.

---

## Installation

Download the `.macro` files from my [GumRoad page](https://efthymisb.gumroad.com/l/tsrvn) or GitHub and place them in any of Katana's startup Macros folder.

- `~/.katana/Macros`

- `custom_path/Startup/Macros`*

_* Custom Paths should be included in KATANA_RESOURCES Environment Variable._

---

## **Special thanks to**:

 > [Jonathan W. Rodegher](https://www.linkedin.com/in/jonathanrodegher/) for suggestions and troubleshooting.

 > [Adam Davis](https://www.linkedin.com/in/adamtdavis/) for sharing his OpScript "Constraint camera focus distance to a locator" in the [Katana Discord Server](https://discord.gg/Rgn9ucN). Was very helpful for some parts of my script.

 > Everyone in **Katana Discord** who helped me.
---

[![](https://img.shields.io/badge/contact-efthymisb.vfx@gmail.com-critical?logo=gmail&logoColor=red)](mailto:efthymisb.vfx@gmail.com)

