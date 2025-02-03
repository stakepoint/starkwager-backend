import { BadRequestException, Inject, Injectable } from '@nestjs/common';
import { UsersService } from 'src/users/users.service';
import { CreateUserDto } from 'src/users/dto/create-user.dto';
import {
  Account,
  RpcProvider,
  TypedData,
  WeierstrassSignatureType,
} from 'starknet';
import { JwtService } from '@nestjs/jwt';
import { ConfigType } from '@nestjs/config';

import { AppConfig } from '../config';
import { User } from '@prisma/client';

@Injectable()
export class AuthService {
  private provider: RpcProvider;

  constructor(
    @Inject(AppConfig.KEY)
    private appConfig: ConfigType<typeof AppConfig>,
    private readonly usersService: UsersService,
    private jwtService: JwtService,
  ) {
    this.provider = new RpcProvider({
      nodeUrl: this.appConfig.nodeUrl,
    });
  }

  async createOrLogin(createUserDto: CreateUserDto) {
    const { address, signature, signedData } = createUserDto;

    // Validate Signature
    if (
      signature &&
      !(await this.isValidSignature(address, signature, signedData))
    ) {
      throw new BadRequestException('Invalid signature');
    }

    // Check existing user by address
    const existingUser = await this.usersService.findOneByAddress(address);
    if (existingUser) {
      const tokens = await this.signJwt(existingUser);
      return {
        message: 'User logged in successfully',
        tokens,
      };
    }

    // If user doesn't exists, create new user and generate access & refresh tokens
    const newUser = await this.usersService.create(createUserDto);

    const tokens = await this.signJwt(newUser);
    return {
      message: 'User Registered successfully',
      user: newUser,
      tokens,
    };
  }

  // Function to validate signature
  private async isValidSignature(
    address: string,
    signature: WeierstrassSignatureType,
    signedData: TypedData,
  ): Promise<boolean> {
    try {
      const account = new Account(this.provider, address, '0x123..');
      const formattedSignature = {
        r: BigInt(signature.r),
        s: BigInt(signature.s),
      } as WeierstrassSignatureType;

      return await account.verifyMessage(signedData, formattedSignature);
    } catch (error) {
      console.error('Signature verification failed:', error.message);
      return false;
    }
  }

  private async signJwt(payload: User) {
    const { address } = payload;
    const accessToken = await this.jwtService.signAsync({
      address,
      sub: payload.id,
      role: payload.roles,
    });

    const refreshToken = await this.jwtService.signAsync(
      {
        address: payload.address,
      },
      {
        secret: this.appConfig.refreshTokenSecret,
        expiresIn: this.appConfig.refreshTokenExpiry,
      },
    );
    return { accessToken, refreshToken };
  }
}
