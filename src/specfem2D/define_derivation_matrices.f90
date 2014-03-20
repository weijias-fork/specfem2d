
!========================================================================
!
!                   S P E C F E M 2 D  Version 7 . 0
!                   --------------------------------
!
! Copyright CNRS, Inria and University of Pau, France,
! and Princeton University / California Institute of Technology, USA.
! Contributors: Dimitri Komatitsch, dimitri DOT komatitsch aT univ-pau DOT fr
!               Nicolas Le Goff, nicolas DOT legoff aT univ-pau DOT fr
!               Roland Martin, roland DOT martin aT univ-pau DOT fr
!               Christina Morency, cmorency aT princeton DOT edu
!
! This software is a computer program whose purpose is to solve
! the two-dimensional viscoelastic anisotropic or poroelastic wave equation
! using a spectral-element method (SEM).
!
! This software is governed by the CeCILL license under French law and
! abiding by the rules of distribution of free software. You can use,
! modify and/or redistribute the software under the terms of the CeCILL
! license as circulated by CEA, CNRS and Inria at the following URL
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

  subroutine define_derivation_matrices(xigll,zigll,wxgll,wzgll,hprime_xx,hprime_zz,hprimewgll_xx,hprimewgll_zz)

  implicit none

  include "constants.h"

! Gauss-Lobatto-Legendre points of integration
  double precision, dimension(NGLLX) :: xigll
  double precision, dimension(NGLLZ) :: zigll

! weights
  real(kind=CUSTOM_REAL), dimension(NGLLX) :: wxgll
  real(kind=CUSTOM_REAL), dimension(NGLLZ) :: wzgll

! array with derivatives of Lagrange polynomials
  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLX) :: hprime_xx,hprimewgll_xx
  real(kind=CUSTOM_REAL), dimension(NGLLZ,NGLLZ) :: hprime_zz,hprimewgll_zz

  double precision, parameter :: alphaGLL = 0.d0, betaGLL = 0.d0

! function for calculating derivatives of Lagrange polynomials
  double precision, external :: lagrange_deriv_GLL

  integer i1,i2,k1,k2

! set up coordinates of the Gauss-Lobatto-Legendre points
  call zwgljd(xigll,wxgll,NGLLX,alphaGLL,betaGLL)
  call zwgljd(zigll,wzgll,NGLLZ,alphaGLL,betaGLL)

! if number of points is odd, the middle abscissa is exactly zero
  if(mod(NGLLX,2) /= 0) xigll((NGLLX-1)/2+1) = ZERO
  if(mod(NGLLZ,2) /= 0) zigll((NGLLZ-1)/2+1) = ZERO

! calculate derivatives of the Lagrange polynomials
! and precalculate some products in double precision
! hprime(i,j) = h'_j(xigll_i) by definition of the derivation matrix
  do i1=1,NGLLX
    do i2=1,NGLLX
      hprime_xx(i2,i1) = lagrange_deriv_GLL(i1-1,i2-1,xigll,NGLLX)
      hprimewgll_xx(i2,i1) = wxgll(i2) * hprime_xx(i2,i1)
    enddo
  enddo

  do k1=1,NGLLZ
    do k2=1,NGLLZ
      hprime_zz(k2,k1) = lagrange_deriv_GLL(k1-1,k2-1,zigll,NGLLZ)
      hprimewgll_zz(k2,k1) = wzgll(k2) * hprime_zz(k2,k1)
    enddo
  enddo

  end subroutine define_derivation_matrices

!____________________________________________________________________________________!axisym
!                                                                                    !axisym
!subroutine define_GLJ_derivation_matrix(xiglj,wxglj,hprimeBar_xx,hprimeBarwglj_xx)  !axisym
! Calculate all that we need for the GLJ quadrature on axial elements :              !axisym
! Weights, GLJ points and derivatives of polynomials at GLJ points.                  !axisym
!____________________________________________________________________________________!axisym
!                                                                                    !axisym
                                                                                     !axisym
  subroutine define_GLJ_derivation_matrix(xiglj,wxglj,hprimeBar_xx,hprimeBarwglj_xx) !axisym
                                                                                     !axisym
  implicit none                                                                      !axisym
                                                                                     !axisym
  include "constants.h"                                                              !axisym
                                                                                     !axisym
! Gauss-Lobatto-Jacobi points of integration                                         !axisym
  double precision, dimension(NGLJ) :: xiglj                                         !axisym
                                                                                     !axisym
! weights for the GLJ quadrature                                                     !axisym
  real(kind=CUSTOM_REAL), dimension(NGLJ) :: wxglj                                   !axisym
                                                                                     !axisym
! array with derivatives of GLJ polynomials                                          !axisym
  real(kind=CUSTOM_REAL), dimension(NGLJ,NGLJ) :: hprimeBar_xx,hprimeBarwglj_xx      !axisym
                                                                                     !axisym
  double precision, parameter    :: alphaGLJ=0.d0,betaGLJ=1.d0                       !axisym
                                                                                     !axisym
! function for calculating derivatives of GLJ polynomials                            !axisym
  double precision, external :: poly_deriv_GLJ                                       !axisym
                                                                                     !axisym
  integer i1,i2                                                                      !axisym
                                                                                     !axisym
! set up coordinates of the Gauss-Lobatto-Jacobi points                              !axisym
  call zwgljd(xiglj,wxglj,NGLJ,alphaGLJ,betaGLJ)                                     !axisym
                                                                                     !axisym
! calculate derivatives of the GLJ quadrature polynomials                            !axisym
! and precalculate some products in double precision                                 !axisym
! hprimeBar(i,j) = hBar'_j(xiglj_i) by definition of the derivation matrix           !axisym
  do i1=1,NGLJ                                                                       !axisym
    do i2=1,NGLJ                                                                     !axisym
      hprimeBar_xx(i2,i1) = poly_deriv_GLJ(i1-1,i2-1,xiglj,NGLJ)                     !axisym
      hprimeBarwglj_xx(i2,i1) = wxglj(i2) * hprimeBar_xx(i2,i1)                      !axisym
    enddo                                                                            !axisym
  enddo                                                                              !axisym
                                                                                     !axisym
  end subroutine define_GLJ_derivation_matrix                                        !axisym

