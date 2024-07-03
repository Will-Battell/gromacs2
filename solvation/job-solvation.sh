#!/bin/bash

#SBATCH --job-name=solvation-energy
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16
#SBATCH --cpus-per-task=1
#SBATCH --time=20:00:00

#SBATCH --account=

#SBATCH --partition=standard
#SBATCH --qos=standard

module load gromacs/2022.4

export OMP_NUM_THREADS=1

# Runs a for loop starting at 0 and ending at 20

for i in {0..20};
do
    # A new directory is made for each lambda step

    mkdir Lambda_$i
    cd Lambda_$i

    # Energy minimisation

    mkdir em
    cd em

    gmx grompp -f ../../mdp-files/em_steep_$i.mdp -c ../../binding-energy.gro -p ../../topol.top -o em$i.tpr -maxwarn 5

    srun gmx_mpi mdrun -s em$i.tpr -c em$i.gro


    # NVT equilibration

    cd ../
    mkdir NVT
    cd NVT

    gmx grompp -f ../../mdp-files/nvt_$i.mdp -c ../em/em$i.gro -p ../../topol.top -o nvt$i.tpr -maxwarn 5

    srun gmx_mpi mdrun -s nvt$i.tpr -c nvt$i.gro

    # NPT equilibration

    cd ../
    mkdir NPT
    cd NPT

    gmx grompp -f ../../mdp-files/npt_$i.mdp -c ../nvt/nvt$i.gro -p ../../topol.top -o npt$i.tpr -maxwarn 5

    srun gmx_mpi mdrun -s npt$i.tpr -c npt$i.gro

    # Production MD

    cd ../
    mkdir Production_MD
    cd Production_MD

    gmx grompp -f ../../mdp-files/md_$i.mdp -c ../npt/npt$i.gro -p ../../topol.top -o md$i.tpr -maxwarn 5

    srun gmx_mpi mdrun -s md$i.tpr -c md$i.gro

    cd ../..

done

exit;
