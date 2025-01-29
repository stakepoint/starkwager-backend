import { BadRequestException, Injectable } from '@nestjs/common';
import { UsersService } from 'src/users/users.service';
import { CreateUserDto } from 'src/users/dto/create-user.dto';
import { Account, RpcProvider, WeierstrassSignatureType } from 'starknet';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private provider: RpcProvider,
    private readonly jwtService: JwtService,
  ) {
    this.provider = new RpcProvider({
      nodeUrl: process.env.NODE_URL,
    });
  }
  async createOrLogin(createUserDto: CreateUserDto) {
    const { address, signature, signedData } = createUserDto;

  // ******************************
    // Validate Signature
    if (
      signature &&
      !(await this.isValidSignature(address, signature, signedData))
    ) {
      throw new BadRequestException('Invalid signature');
    }

    // ******************************
    // Check existing user by address
    const existingUser = await this.usersService.findOneByAddress(address);
    if (existingUser) {
      const tokens = await this.generateTokens(existingUser); // If user exists generate access & refresh tokens
      return {
        message: 'User logged in successfully',
        tokens,
      };
    }

  // ******************************
  // If user doesn't exists, create new user and generate access & refresh tokens
  const newUser = await this.usersService.create(createUserDto);
  const tokens = await this.generateTokens(newUser);
    return {
      message: 'User Registered successfully',
      user: newUser,
      tokens,
    };
  }
  // ******************************
  // Function to validate signature
  private async isValidSignature(
    address: string,
    signature: WeierstrassSignatureType,
    signedData: string,
  ): Promise<boolean> {
    try {
      const account = new Account(this.provider, address, '0x123..');
      const formattedSignature = {
        r: BigInt(signature.r),
        s: BigInt(signature.s),
      } as WeierstrassSignatureType;

      const messageStructure = {
        types: {
          StarkNetDomain: [
            { name: 'StarkWager', type: 'felt' },
            { name: process.env.CHAIN_ID, type: 'felt' },
            { name: 'version', type: 'felt' },
          ],
          Message: [{ name: 'message', type: 'felt' }],
        },
        primaryType: 'Message',
        domain: {
          name: 'StarkWager',
          chainId: process.env.CHAIN_ID,
          version: '0.0.1',
        },
        message: {
          message: signedData,
        },
      };

      return await account.verifyMessage(messageStructure, formattedSignature);
    } catch (error) {
      console.error('Signature verification failed:', error.message);
      return false;
    }
  }

  // ******************************
  // Function to generate token
  private async generateTokens(user: any) {
    const payload = { address: user.address, sub: user.id };
    const secret = process.env.JWT_SECRET;
    const accessToken = this.jwtService.sign(payload, {
      secret,
      expiresIn: process.env.JWT_ACCESS_EXPIRTY_TIME,
    });
    const refreshToken = this.jwtService.sign(payload, {
      secret,
      expiresIn: process.env.JWT_REFRESH_EXPIRTY_TIME,
    });

    return { accessToken, refreshToken };
  }
}
