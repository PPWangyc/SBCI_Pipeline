import argparse
import logging
import numpy as np
import vtk

from collections import defaultdict
from os.path import isfile

DESCRIPTION = """
  Generate a mapping between the high and low resolution surfaces used.
"""


def _build_args_parser():
    p = argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter,
                                description=DESCRIPTION)

    p.add_argument('--lh_surface_hi', action='store', metavar='LH_SURFACE_HI', required=True,
                   type=str, help='Path of the high resolution .vtk mesh file for the left hemisphere.')

    p.add_argument('--lh_surface_lo', action='store', metavar='LH_SURFACE_LO', required=True,
                   type=str, help='Path of the low resolution .vtk mesh file for the left hemisphere.')

    p.add_argument('--rh_surface_hi', action='store', metavar='RH_SURFACE_HI', required=True,
                   type=str, help='Path of the high resolution .vtk mesh file for the right hemisphere.')

    p.add_argument('--rh_surface_lo', action='store', metavar='RH_SURFACE_LO', required=True,
                   type=str, help='Path of the low resolution .vtk mesh file for the right hemisphere.')

    p.add_argument('--output', action='store', metavar='OUTPUT', required=True,
                   type=str, help='Path of the .npz file to save the output to.')

    p.add_argument('-f', action='store_true', dest='overwrite',
                   help='If set, overwrite files if they already exist.')

    return p


# helper function to load the .vtk surfaces
def load_vtk(filename):
    reader = vtk.vtkPolyDataReader()
    reader.SetFileName(filename)
    reader.Update()

    return reader.GetOutput()


# load all the required surfaces and build locator algorithms
def initialise_surfaces(surface_files):
    surfaces = dict()
    points = dict()
    locators = dict()

    # load all low res surfaces 
    surfaces[0] = load_vtk(surface_files[1])
    surfaces[1] = load_vtk(surface_files[3])

    # initialise locator algorithms for the downsampled mesh
    locators[0] = vtk.vtkCellLocator()
    locators[0].SetDataSet(surfaces[0])
    locators[0].BuildLocator()

    locators[1] = vtk.vtkCellLocator()
    locators[1].SetDataSet(surfaces[1])
    locators[1].BuildLocator()

    # load points for high res surfaces
    points[0] = load_vtk(surface_files[0]).GetPoints()
    points[1] = load_vtk(surface_files[2]).GetPoints()

    return surfaces, points, locators


# snap the given vertex to the nearest vertex of the given triangle
def snap_to_closest_vertex(cell, intersection):
    poly_pts = cell.GetPoints()
    triangle = np.array([poly_pts.GetPoint(j) for j in range(poly_pts.GetNumberOfPoints())])

    # vectorise squared euler distance between the intersection and the triangle, return index of closest vertex
    dist = np.sum((triangle - intersection)**2, axis=1)
    tri_id = np.argmin(dist)
    vertex_id = cell.GetPointIds().GetId(tri_id)

    # populate the result arrays
    return vertex_id


def main():
    parser = _build_args_parser()
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO)

    # make sure all the given files exist
    if not isfile(args.lh_surface_hi):
        parser.error('The file "{0}" must exist.'.format(args.lh_surface_hi))

    if not isfile(args.lh_surface_lo):
        parser.error('The file "{0}" must exist.'.format(args.lh_surface_lo))

    if not isfile(args.rh_surface_hi):
        parser.error('The file "{0}" must exist.'.format(args.rh_surface_hi))

    if not isfile(args.rh_surface_lo):
        parser.error('The file "{0}" must exist.'.format(args.rh_surface_lo))

    # make sure that files are not accidently overwritten
    if isfile(args.output):
        if args.overwrite:
            logging.info('Overwriting "{0}".'.format(args.output))
        else:
            parser.error('The file "{0}" already exists. Use -f to overwrite it.'.format(args.output))

    logging.info('Loading .vtk surfaces, mapping, and intersections.')

    # load the low resolution surfaces, the vertices of the high resolution surfaces, and initialise cell locator algorithms
    surfaces, points, locators = initialise_surfaces([args.lh_surface_hi, args.lh_surface_lo, args.rh_surface_hi, args.rh_surface_lo])

    lh_surf_n = surfaces[0].GetNumberOfPoints()
    rh_surf_n = surfaces[1].GetNumberOfPoints()
    surf_n = lh_surf_n + rh_surf_n

    lh_orig_n = points[0].GetNumberOfPoints()
    rh_orig_n = points[1].GetNumberOfPoints()
    orig_n = lh_orig_n + rh_orig_n

    # initialise pointers for cell locator
    intersection = [0, 0, 0]
    cell_id = vtk.reference(0)
    sub_id = vtk.reference(0)
    d = vtk.reference(0)

    offset = 0
    snapped = defaultdict(list)

    leftvertex = np.empty(lh_surf_n, np.int64)
    rightvertex = np.empty(rh_surf_n, np.int64)

    logging.info('Snapping mesh to nearest downsampled vertices.')

    # loop through all vertices on full mesh and assign them to the closest vertex on resampled mesh
    for surface_id in range(len(surfaces)):
        n = points[surface_id].GetNumberOfPoints()

        count = 0
        for i in range(n):
            # find the closest point and triangle of the lower resolution mesh to a given vertex on the full mesh
            locators[surface_id].FindClosestPoint(points[surface_id].GetPoint(i), intersection, cell_id, sub_id, d)

            # snap the in point to the closest vertex on the mesh (vertex 0 on rh side is equal to the number of vertices on lh side).
            index = snap_to_closest_vertex(surfaces[surface_id].GetCell(cell_id.get()), intersection)
            snapped[index + offset].append(i + offset)

            if np.array_equal(points[surface_id].GetPoint(i), surfaces[surface_id].GetPoints().GetPoint(index)):
                if offset == 0:
                    leftvertex[index] = i
                else:
                    rightvertex[index] = i

                count = count + 1

        offset = offset + n

    # get the shape of the original mesh, and the new mesh
    vertices = snapped.values()
    n = len(vertices)

    # make sure nothing went wrong
    if not n == surf_n:
        logging.info('Warning: Mesh and mapping have different number of points.')

    # save the shape of the original and new mesh
    shape = np.array([surf_n, lh_surf_n, rh_surf_n, orig_n, lh_orig_n, rh_orig_n])

    # save the results: mapping contains arrays of vertex numbers from original mesh that have been assigned to each
    # of the vertices of the downsampled mesh; shape has the number of vertices for both high and low resolution meshes.
    np.savez_compressed(args.output, mapping=vertices, shape=shape, lh_ids=leftvertex, rh_ids=rightvertex)


if __name__ == "__main__":
    main()