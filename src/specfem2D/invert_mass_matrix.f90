
!========================================================================
!
!                   S P E C F E M 2 D  Version 6 . 2
!                   ------------------------------
!
! Copyright Universite de Pau, CNRS and INRIA, France,
! and Princeton University / California Institute of Technology, USA.
! Contributors: Dimitri Komatitsch, dimitri DOT komatitsch aT univ-pau DOT fr
!               Nicolas Le Goff, nicolas DOT legoff aT univ-pau DOT fr
!               Roland Martin, roland DOT martin aT univ-pau DOT fr
!               Christina Morency, cmorency aT princeton DOT edu
!               Pieyre Le Loher, pieyre DOT le-loher aT inria.fr
!
! This software is a computer program whose purpose is to solve
! the two-dimensional viscoelastic anisotropic or poroelastic wave equation
! using a spectral-element method (SEM).
!
! This software is governed by the CeCILL license under French law and
! abiding by the rules of distribution of free software. You can use,
! modify and/or redistribute the software under the terms of the CeCILL
! license as circulated by CEA, CNRS and INRIA at the following URL
! "http://www.cecill.info".
!
! As a counterpart to the access to the source code and rights to copy,
! modify and redistribute granted by the license, users are provided only
! with a limited warranty and the software's author, the holder of the
! economic rights, and the successive licensors have only limited
! liability.
!
! In this respect, the user's attention is drawn to the risks associated
! with loading, using, modifying and/or developing or reproducing the
! software by the user in light of its specific status of free software,
! that may mean that it is complicated to manipulate, and that also
! therefore means that it is reserved for developers and experienced
! professionals having in-depth computer knowledge. Users are therefore
! encouraged to load and test the software's suitability as regards their
! requirements in conditions enabling the security of their systems and/or
! data to be ensured and, more generally, to use and operate it in the
! same conditions as regards security.
!
! The full text of the license is available in file "LICENSE".
!
!========================================================================

  subroutine invert_mass_matrix_init(any_elastic,any_acoustic,any_poroelastic, &
                                rmass_inverse_elastic_one,nglob_elastic, &
                                rmass_inverse_acoustic,nglob_acoustic, &
                                rmass_s_inverse_poroelastic, &
                                rmass_w_inverse_poroelastic,nglob_poroelastic, &
                                nspec,ibool,kmato,wxgll,wzgll,jacobian, &
                                elastic,poroelastic, &
                                assign_external_model,numat, &
                                density,poroelastcoef,porosity,tortuosity, &
                                vpext,rhoext,&
   anyabs,numabs,deltat,codeabs,rmass_inverse_elastic_three,&
   nelemabs,vsext,xix,xiz,gammaz,gammax)

!  builds the global mass matrix

  implicit none
  include 'constants.h'

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  logical :: anyabs
  integer :: nelemabs,ibegin,iend,ispecabs
!  integer :: ispec,i,j,k,iglob,ispecabs,ibegin,iend,irec,irec_local
  integer, dimension(nelemabs) :: numabs
  double precision :: deltat
  logical, dimension(4,nelemabs)  :: codeabs

!!local parameter
  ! material properties of the elastic medium
  real(kind=CUSTOM_REAL) :: mul_unrelaxed_elastic,lambdal_unrelaxed_elastic,cpl,csl
  integer count_left,count_right,count_bottom
  real(kind=CUSTOM_REAL) :: nx,nz,vx,vy,vz,vn,rho_vp,rho_vs,tx,ty,tz,&
                            weight,xxi,zxi,xgamma,zgamma,jacobian1D

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  logical any_elastic,any_acoustic,any_poroelastic

  ! inverse mass matrices
  integer :: nglob_elastic

 real(kind=CUSTOM_REAL), dimension(nglob_elastic) :: rmass_inverse_elastic_one,&  !zhinan
                                                     rmass_inverse_elastic_three

  integer :: nglob_acoustic
  real(kind=CUSTOM_REAL), dimension(nglob_acoustic) :: rmass_inverse_acoustic

  integer :: nglob_poroelastic
  real(kind=CUSTOM_REAL), dimension(nglob_poroelastic) :: &
    rmass_s_inverse_poroelastic,rmass_w_inverse_poroelastic

  integer :: nspec
  integer, dimension(NGLLX,NGLLZ,nspec) :: ibool
  integer, dimension(nspec) :: kmato
  real(kind=CUSTOM_REAL), dimension(NGLLX) :: wxgll
  real(kind=CUSTOM_REAL), dimension(NGLLX) :: wzgll
  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLZ,nspec) :: jacobian

  logical,dimension(nspec) :: elastic,poroelastic

  logical :: assign_external_model
  integer :: numat
  double precision, dimension(2,numat) :: density
  double precision, dimension(4,3,numat) :: poroelastcoef
  double precision, dimension(numat) :: porosity,tortuosity
  double precision, dimension(NGLLX,NGLLX,nspec) :: vpext,rhoext,vsext !zhinan

  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLZ,nspec) :: xix,xiz,gammax,gammaz  !zhinan

  ! local parameters
  integer :: ispec,i,j,iglob
  double precision :: rhol,kappal,mul_relaxed,lambdal_relaxed
  double precision :: rhol_s,rhol_f,rhol_bar,phil,tortl

  ! initializes mass matrix
  if(any_elastic) rmass_inverse_elastic_one(:) = 0._CUSTOM_REAL
  if(any_elastic) rmass_inverse_elastic_three(:) = 0._CUSTOM_REAL
  if(any_poroelastic) rmass_s_inverse_poroelastic(:) = 0._CUSTOM_REAL
  if(any_poroelastic) rmass_w_inverse_poroelastic(:) = 0._CUSTOM_REAL
  if(any_acoustic) rmass_inverse_acoustic(:) = 0._CUSTOM_REAL

  do ispec = 1,nspec
    do j = 1,NGLLZ
      do i = 1,NGLLX
        iglob = ibool(i,j,ispec)

        ! if external density model (elastic or acoustic)
        if(assign_external_model) then
          rhol = rhoext(i,j,ispec)
          kappal = rhol * vpext(i,j,ispec)**2
        else
          rhol = density(1,kmato(ispec))
          lambdal_relaxed = poroelastcoef(1,1,kmato(ispec))
          mul_relaxed = poroelastcoef(2,1,kmato(ispec))
          kappal = lambdal_relaxed + 2.d0/3.d0*mul_relaxed
        endif

        if( poroelastic(ispec) ) then

          ! material is poroelastic

          rhol_s = density(1,kmato(ispec))
          rhol_f = density(2,kmato(ispec))
          phil = porosity(kmato(ispec))
          tortl = tortuosity(kmato(ispec))
          rhol_bar = (1.d0-phil)*rhol_s + phil*rhol_f

          ! for the solid mass matrix
          rmass_s_inverse_poroelastic(iglob) = rmass_s_inverse_poroelastic(iglob)  &
                  + wxgll(i)*wzgll(j)*jacobian(i,j,ispec)*(rhol_bar - phil*rhol_f/tortl)
          ! for the fluid mass matrix
          rmass_w_inverse_poroelastic(iglob) = rmass_w_inverse_poroelastic(iglob) &
                  + wxgll(i)*wzgll(j)*jacobian(i,j,ispec)*(rhol_bar*rhol_f*tortl  &
                  - phil*rhol_f*rhol_f)/(rhol_bar*phil)

        elseif( elastic(ispec) ) then

          ! for elastic medium
          rmass_inverse_elastic_one(iglob) = rmass_inverse_elastic_one(iglob)  &
                  + wxgll(i)*wzgll(j)*rhol*jacobian(i,j,ispec)
          rmass_inverse_elastic_three(iglob) = rmass_inverse_elastic_one(iglob)

 
        else

          ! for acoustic medium

          rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                  + wxgll(i)*wzgll(j)*jacobian(i,j,ispec) / kappal

        endif

      enddo
    enddo
  enddo ! do ispec = 1,nspec

  !
  !--- DK and Zhinan Xie: add C Delta_t / 2 contribution to the mass matrix
  !--- DK and Zhinan Xie: in the case of Clayton-Engquist absorbing boundaries;
  !--- DK and Zhinan Xie: see for instance the book of Hughes (1987) chapter 9.
  !--- DK and Zhinan Xie: IMPORTANT: note that this implies that we must have two different mass matrices,
  !--- DK and Zhinan Xie: one per component of the wave field i.e. one per spatial dimension.
  !--- DK and Zhinan Xie: This was also suggested by Jean-Paul Ampuero in 2003.
  !
  if(anyabs) then
     count_left=1
     count_right=1
     count_bottom=1
     do ispecabs = 1,nelemabs
        ispec = numabs(ispecabs)
        ! get elastic parameters of current spectral elemegammaznt
        lambdal_unrelaxed_elastic = poroelastcoef(1,1,kmato(ispec))
        mul_unrelaxed_elastic = poroelastcoef(2,1,kmato(ispec))
        rhol  = density(1,kmato(ispec))
        kappal  = lambdal_unrelaxed_elastic + TWO*mul_unrelaxed_elastic/3._CUSTOM_REAL
        cpl = sqrt((kappal + 4._CUSTOM_REAL*mul_unrelaxed_elastic/3._CUSTOM_REAL)/rhol)
        csl = sqrt(mul_unrelaxed_elastic/rhol)

        !--- left absorbing boundary
        if(codeabs(ILEFT,ispecabs)) then

           i = 1

           do j = 1,NGLLZ

              iglob = ibool(i,j,ispec)

              ! external velocity model
              if(assign_external_model) then
                 cpl = vpext(i,j,ispec)
                 csl = vsext(i,j,ispec)
                 rhol = rhoext(i,j,ispec)
              endif

              rho_vp = rhol*cpl
              rho_vs = rhol*csl

              xgamma = - xiz(i,j,ispec) * jacobian(i,j,ispec)
              zgamma = + xix(i,j,ispec) * jacobian(i,j,ispec)
              jacobian1D = sqrt(xgamma**2 + zgamma**2)
              nx = - zgamma / jacobian1D
              nz = + xgamma / jacobian1D

              weight = jacobian1D * wzgll(j)

              ! Clayton-Engquist condition if elastic
              if(elastic(ispec)) then

                 vx = 1.0d0*deltat/2.0d0
                 vy = 1.0d0*deltat/2.0d0
                 vz = 1.0d0*deltat/2.0d0

                 vn = nx*vx+nz*vz

                 tx = rho_vp*vn*nx+rho_vs*(vx-vn*nx)
                 ty = rho_vs*vy
                 tz = rho_vp*vn*nz+rho_vs*(vz-vn*nz)

                rmass_inverse_elastic_one(iglob) = rmass_inverse_elastic_one(iglob)  &
                    + (tx)*weight
                rmass_inverse_elastic_three(iglob) = rmass_inverse_elastic_one(iglob)  &
                    + (tz)*weight

              endif
           enddo

        endif  !  end of left absorbing boundary

        !--- right absorbing boundary
        if(codeabs(IRIGHT,ispecabs)) then

           i = NGLLX

           do j = 1,NGLLZ

              iglob = ibool(i,j,ispec)

              ! for analytical initial plane wave for Bielak's conditions
              ! left or right edge, horizontal normal vector

              ! external velocity model
              if(assign_external_model) then
                 cpl = vpext(i,j,ispec)
                 csl = vsext(i,j,ispec)
                 rhol = rhoext(i,j,ispec)
              endif

              rho_vp = rhol*cpl
              rho_vs = rhol*csl

              xgamma = - xiz(i,j,ispec) * jacobian(i,j,ispec)
              zgamma = + xix(i,j,ispec) * jacobian(i,j,ispec)
              jacobian1D = sqrt(xgamma**2 + zgamma**2)
              nx = + zgamma / jacobian1D
              nz = - xgamma / jacobian1D

              weight = jacobian1D * wzgll(j)

              ! Clayton-Engquist condition if elastic
              if(elastic(ispec)) then

                 vx = 1.0d0*deltat/2.0d0
                 vy = 1.0d0*deltat/2.0d0
                 vz = 1.0d0*deltat/2.0d0

                 vn = nx*vx+nz*vz

                 tx = rho_vp*vn*nx+rho_vs*(vx-vn*nx)
                 ty = rho_vs*vy
                 tz = rho_vp*vn*nz+rho_vs*(vz-vn*nz)

                rmass_inverse_elastic_one(iglob) = rmass_inverse_elastic_one(iglob)  &
                    + (tx)*weight
                rmass_inverse_elastic_three(iglob) = rmass_inverse_elastic_one(iglob)  &
                    + (tz)*weight

              endif

           enddo

        endif  !  end of right absorbing boundary

        !--- bottom absorbing boundary
        if(codeabs(IBOTTOM,ispecabs)) then

           j = 1
           ibegin = 1
           iend = NGLLX

           do i = ibegin,iend

              iglob = ibool(i,j,ispec)
              ! external velocity model
              if(assign_external_model) then
                 cpl = vpext(i,j,ispec)
                 csl = vsext(i,j,ispec)
                 rhol = rhoext(i,j,ispec)
              endif

              rho_vp = rhol*cpl
              rho_vs = rhol*csl

              xxi = + gammaz(i,j,ispec) * jacobian(i,j,ispec)
              zxi = - gammax(i,j,ispec) * jacobian(i,j,ispec)
              jacobian1D = sqrt(xxi**2 + zxi**2)
              nx = + zxi / jacobian1D
              nz = - xxi / jacobian1D

              weight = jacobian1D * wxgll(i)

              ! Clayton-Engquist condition if elastic
              if(elastic(ispec)) then

                 vx = 1.0d0*deltat/2.0d0
                 vy = 1.0d0*deltat/2.0d0
                 vz = 1.0d0*deltat/2.0d0

                 vn = nx*vx+nz*vz

                 tx = rho_vp*vn*nx+rho_vs*(vx-vn*nx)
                 ty = rho_vs*vy
                 tz = rho_vp*vn*nz+rho_vs*(vz-vn*nz)

! exclude corners to make sure there is no contradiction on the normal
! for Stacey absorbing conditions but not for incident plane waves;
! thus subtract nothing i.e. zero in that case
                 if((codeabs(ILEFT,ispecabs) .and. i == 1) .or. (codeabs(IRIGHT,ispecabs) .and. i == NGLLX)) then
                   tx = 0
                   ty = 0
                   tz = 0
                rmass_inverse_elastic_one(iglob) = rmass_inverse_elastic_one(iglob)
                rmass_inverse_elastic_three(iglob) = rmass_inverse_elastic_three(iglob)
                 else
                rmass_inverse_elastic_one(iglob) = rmass_inverse_elastic_one(iglob)  &
                    + (tx)*weight
                rmass_inverse_elastic_three(iglob) = rmass_inverse_elastic_one(iglob)  &
                    + (tz)*weight
                 endif

             endif

           enddo

        endif  !  end of bottom absorbing boundary

        !--- top absorbing boundary
        if(codeabs(ITOP,ispecabs)) then

           j = NGLLZ

           ibegin = 1
           iend = NGLLX

           do i = ibegin,iend

              iglob = ibool(i,j,ispec)

              ! external velocity model
              if(assign_external_model) then
                 cpl = vpext(i,j,ispec)
                 csl = vsext(i,j,ispec)
                 rhol = rhoext(i,j,ispec)
              endif

              rho_vp = rhol*cpl
              rho_vs = rhol*csl

              xxi = + gammaz(i,j,ispec) * jacobian(i,j,ispec)
              zxi = - gammax(i,j,ispec) * jacobian(i,j,ispec)
              jacobian1D = sqrt(xxi**2 + zxi**2)
              nx = - zxi / jacobian1D
              nz = + xxi / jacobian1D

              weight = jacobian1D * wxgll(i)

              ! Clayton-Engquist condition if elastic
              if(elastic(ispec)) then

                 vx = 1.0d0*deltat/2.0d0
                 vy = 1.0d0*deltat/2.0d0
                 vz = 1.0d0*deltat/2.0d0

                 vn = nx*vx+nz*vz

                 tx = rho_vp*vn*nx+rho_vs*(vx-vn*nx)
                 ty = rho_vs*vy
                 tz = rho_vp*vn*nz+rho_vs*(vz-vn*nz)

! exclude corners to make sure there is no contradiction on the normal
! for Stacey absorbing conditions but not for incident plane waves;
! thus subtract nothing i.e. zero in that case
                 if((codeabs(ILEFT,ispecabs) .and. i == 1) .or. (codeabs(IRIGHT,ispecabs) .and. i == NGLLX)) then
                   tx = 0
                   ty = 0
                   tz = 0
                rmass_inverse_elastic_one(iglob) = rmass_inverse_elastic_one(iglob)
                rmass_inverse_elastic_three(iglob) = rmass_inverse_elastic_three(iglob)
                 else
                rmass_inverse_elastic_one(iglob) = rmass_inverse_elastic_one(iglob)  &
                    + (tx)*weight
                rmass_inverse_elastic_three(iglob) = rmass_inverse_elastic_one(iglob)  &
                    + (tz)*weight
                 endif
            endif


           enddo
        endif  !  end of top absorbing boundary
     enddo
  endif  ! end of absorbing boundaries


  end subroutine invert_mass_matrix_init
!
!-------------------------------------------------------------------------------------------------
!

  subroutine invert_mass_matrix(any_elastic,any_acoustic,any_poroelastic, &
                                rmass_inverse_elastic_one,rmass_inverse_elastic_three,&
                                nglob_elastic, &
                                rmass_inverse_acoustic,nglob_acoustic, &
                                rmass_s_inverse_poroelastic, &
                                rmass_w_inverse_poroelastic,nglob_poroelastic)

! inverts the global mass matrix

  implicit none
  include 'constants.h'

  logical any_elastic,any_acoustic,any_poroelastic

! inverse mass matrices
  integer :: nglob_elastic
  real(kind=CUSTOM_REAL), dimension(nglob_elastic) :: rmass_inverse_elastic_one,&
                                                      rmass_inverse_elastic_three

  integer :: nglob_acoustic
  real(kind=CUSTOM_REAL), dimension(nglob_acoustic) :: rmass_inverse_acoustic

  integer :: nglob_poroelastic
  real(kind=CUSTOM_REAL), dimension(nglob_poroelastic) :: &
    rmass_s_inverse_poroelastic,rmass_w_inverse_poroelastic


! fill mass matrix with fictitious non-zero values to make sure it can be inverted globally
  if(any_elastic) &
    where(rmass_inverse_elastic_one <= 0._CUSTOM_REAL) rmass_inverse_elastic_one = 1._CUSTOM_REAL
  if(any_elastic) &
    where(rmass_inverse_elastic_three <= 0._CUSTOM_REAL) rmass_inverse_elastic_three = 1._CUSTOM_REAL
  if(any_poroelastic) &
    where(rmass_s_inverse_poroelastic <= 0._CUSTOM_REAL) rmass_s_inverse_poroelastic = 1._CUSTOM_REAL
  if(any_poroelastic) &
    where(rmass_w_inverse_poroelastic <= 0._CUSTOM_REAL) rmass_w_inverse_poroelastic = 1._CUSTOM_REAL
  if(any_acoustic) &
    where(rmass_inverse_acoustic <= 0._CUSTOM_REAL) rmass_inverse_acoustic = 1._CUSTOM_REAL

! compute the inverse of the mass matrix
  if(any_elastic) &
    rmass_inverse_elastic_one(:) = 1._CUSTOM_REAL / rmass_inverse_elastic_one(:)
  if(any_elastic) &
    rmass_inverse_elastic_three(:) = 1._CUSTOM_REAL / rmass_inverse_elastic_three(:)
  if(any_poroelastic) &
    rmass_s_inverse_poroelastic(:) = 1._CUSTOM_REAL / rmass_s_inverse_poroelastic(:)
  if(any_poroelastic) &
    rmass_w_inverse_poroelastic(:) = 1._CUSTOM_REAL / rmass_w_inverse_poroelastic(:)
  if(any_acoustic) &
    rmass_inverse_acoustic(:) = 1._CUSTOM_REAL / rmass_inverse_acoustic(:)

  end subroutine invert_mass_matrix
