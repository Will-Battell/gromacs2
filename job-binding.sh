#!/bin/bash

#SBATCH --job-name=energy-binding
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16
#SBATCH --cpus-per-task=1
#SBATCH --time=20:00:00

#SBATCH --account=e793-wbattell

#SBATCH --partition=standard
#SBATCH --qos=standard

module load gromacs/2022.4

export OMP_NUM_THREADS=1

# Set some environment variables
FREE_ENERGY=/work/e793/e793/wbattell/binding-energy/binding-energy

echo "Free energy home directory set to $FREE_ENERGY"
MDP=$FREE_ENERGY/MDP
echo ".mdp files are stored in $MDP"


for (( i=0; i<21; i++ ))
do
    LAMBDA=$i

    # A new directory will be created for each value of lambda and
    # at each step in the workflow for maximum organization.

    mkdir Lambda_$LAMBDA
    cd Lambda_$LAMBDA

    ##############################
    # ENERGY MINIMIZATION STEEP  #
    ##############################
    echo "Starting minimization for lambda = $LAMBDA..." 

    mkdir EM
    cd EM

    # Iterative calls to grompp and mdrun to run the simulations

    gmx grompp -f $MDP/em_steep_$LAMBDA.mdp -c $FREE_ENERGY/8B2T-nirma-bigger-box-5nm.gro -p $FREE_ENERGY/topol.top -o min$LAMBDA.tpr -maxwarn 5

    srun gmx_mpi mdrun -deffnm min$LAMBDA

    sleep 2

    #####################
    # NVT EQUILIBRATION #
    #####################
    echo "Starting constant volume equilibration..."

    cd ../
    mkdir NVT
    cd NVT

    gmx grompp -f $MDP/nvt_$LAMBDA.mdp -c ../EM/min$LAMBDA.gro -p $FREE_ENERGY/topol.top -o nvt$LAMBDA.tpr -maxwarn 5

    srun gmx_mpi mdrun -deffnm nvt$LAMBDA

    echo "Constant volume equilibration complete."

    sleep 2

    #####################
    # NPT EQUILIBRATION #
    #####################
    echo "Starting constant pressure equilibration..."

    cd ../
    mkdir NPT
    cd NPT

    gmx grompp -f $MDP/npt_$LAMBDA.mdp -c ../NVT/nvt$LAMBDA.gro -p $FREE_ENERGY/topol.top -t ../NVT/nvt$LAMBDA.cpt -o npt$LAMBDA.tpr -maxwarn 5

    srun gmx_mpi mdrun -deffnm npt$LAMBDA

    echo "Constant pressure equilibration complete."

    sleep 2

    #################
    # PRODUCTION MD #
    #################
    echo "Starting production MD simulation..."

    cd ../
    mkdir Production_MD
    cd Production_MD

    gmx grompp -f $MDP/md_$LAMBDA.mdp -c ../NPT/npt$LAMBDA.gro -p $FREE_ENERGY/topol.top -t ../NPT/npt$LAMBDA.cpt -o md$LAMBDA.tpr -maxwarn 5

    srun gmx_mpi mdrun -deffnm md$LAMBDA

    echo "Production MD complete."

    # End
    echo "Ending. Job completed for lambda = $LAMBDA"

    cd $FREE_ENERGY
done

exit;
